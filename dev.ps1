[CmdletBinding(SupportsShouldProcess = $true)]
param(
    [Parameter(Position = 0)]
    [ValidateSet('format', 'analyze', 'lint', 'build', 'import', 'test', 'verify', 'ci', 'bump', 'release')]
    [string]$Command,

    [Parameter(Position = 1)]
    [string]$Argument
)

Set-StrictMode -Version 2.0
$ErrorActionPreference = 'Stop'

$repositoryRoot = $PSScriptRoot
$moduleSourceDirectory = Join-Path -Path $repositoryRoot -ChildPath 'src/PSWinUtil'
$buildConfigurationPath = Join-Path -Path $moduleSourceDirectory -ChildPath 'build.psd1'
$sourceManifestPath = Join-Path -Path $moduleSourceDirectory -ChildPath 'PSWinUtil.psd1'
$outputModuleDirectory = Join-Path -Path $repositoryRoot -ChildPath 'output/PSWinUtil'
$outputManifestPath = Join-Path -Path $outputModuleDirectory -ChildPath 'PSWinUtil.psd1'
$outputModulePath = Join-Path -Path $outputModuleDirectory -ChildPath 'PSWinUtil.psm1'
$outputLibraryDirectory = Join-Path -Path $outputModuleDirectory -ChildPath 'lib'
$outputTestSupportDirectory = Join-Path -Path $repositoryRoot -ChildPath 'output/TestSupport'
$dotnetBuildDirectory = Join-Path -Path $repositoryRoot -ChildPath 'output/dotnet'
$nativeProjectPath = Join-Path `
    -Path $repositoryRoot `
    -ChildPath 'src/PSWinUtil.Native/PSWinUtil.Native.csproj'
$testSupportProjectPath = Join-Path `
    -Path $repositoryRoot `
    -ChildPath 'tests/PSWinUtil.TestSupport/PSWinUtil.TestSupport.csproj'
$formatterSettingsPath = Join-Path -Path $repositoryRoot -ChildPath 'PSScriptFormatterSettings.psd1'
$analyzerSettingsPath = Join-Path -Path $repositoryRoot -ChildPath 'PSScriptAnalyzerSettings.psd1'
$requirementsPath = Join-Path -Path $repositoryRoot -ChildPath 'build.requirements.psd1'

$writeUsage = {
    Write-Output -InputObject @'
Usage:
  .\dev.ps1 format
  .\dev.ps1 analyze
  .\dev.ps1 lint
  .\dev.ps1 build
  .\dev.ps1 import
  .\dev.ps1 test unit
  .\dev.ps1 test integration
  .\dev.ps1 test contract
  .\dev.ps1 test all
  .\dev.ps1 verify
  .\dev.ps1 ci
  .\dev.ps1 bump 1.2.3
  .\dev.ps1 release
'@
}

$isDotSourced = $MyInvocation.InvocationName -eq '.'

if ([string]::IsNullOrWhiteSpace($Command) -and -not $isDotSourced) {
    & $writeUsage
    exit 0
}

if (-not (Test-Path -LiteralPath $requirementsPath -PathType Leaf)) {
    throw "Development module requirements were not found: $requirementsPath"
}

$requirements = Import-PowerShellDataFile -Path $requirementsPath

$importRequiredModule = {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Name
    )

    if (-not $requirements.ContainsKey($Name)) {
        throw "A required development module is not pinned: $Name"
    }

    $requiredVersion = [string]$requirements[$Name]
    try {
        Import-Module -Name $Name -RequiredVersion $requiredVersion -Force -ErrorAction Stop
    } catch {
        throw "Install $Name $requiredVersion before running this command. $($_.Exception.Message)"
    }
}

$getSourceFiles = {
    $rootFileNames = @(
        'install.ps1'
        'dev.ps1'
        'build.requirements.psd1'
        'PSScriptFormatterSettings.psd1'
        'PSScriptAnalyzerSettings.psd1'
    )
    $files = @()

    foreach ($rootFileName in $rootFileNames) {
        $rootFilePath = Join-Path -Path $repositoryRoot -ChildPath $rootFileName
        if (Test-Path -LiteralPath $rootFilePath -PathType Leaf) {
            $files += Get-Item -LiteralPath $rootFilePath
        }
    }

    $sourceDirectories = @(
        $moduleSourceDirectory
        (Join-Path -Path $repositoryRoot -ChildPath 'tests')
    )
    foreach ($sourceDirectory in $sourceDirectories) {
        if (-not (Test-Path -LiteralPath $sourceDirectory -PathType Container)) {
            continue
        }

        $files += Get-ChildItem -LiteralPath $sourceDirectory -File -Recurse |
            Where-Object { $_.Extension -in @('.ps1', '.psd1', '.ps1xml') }
    }

    @($files | Sort-Object -Property FullName -Unique)
}

$getDotnetSourceFiles = {
    $projectDirectories = @(
        (Split-Path -Path $nativeProjectPath -Parent)
        (Split-Path -Path $testSupportProjectPath -Parent)
    )
    $files = @()

    foreach ($projectDirectory in $projectDirectories) {
        if (-not (Test-Path -LiteralPath $projectDirectory -PathType Container)) {
            continue
        }

        $files += Get-ChildItem -LiteralPath $projectDirectory -File -Recurse |
            Where-Object {
                $_.Extension -in @('.cs', '.csproj') -and
                $_.FullName -notmatch '[\\/](bin|obj)[\\/]'
            }
    }

    @($files | Sort-Object -Property FullName -Unique)
}

$assertAsciiFile = {
    param(
        [Parameter(Mandatory = $true)]
        [System.IO.FileInfo]$File
    )

    [byte[]]$bytes = [System.IO.File]::ReadAllBytes($File.FullName)
    if (
        $bytes.Length -ge 3 -and
        $bytes[0] -eq 0xEF -and
        $bytes[1] -eq 0xBB -and
        $bytes[2] -eq 0xBF
    ) {
        throw "A UTF-8 BOM is not allowed: $($File.FullName)"
    }

    if ($bytes -contains 0x0D) {
        throw "A carriage return is not allowed: $($File.FullName)"
    }

    foreach ($byte in $bytes) {
        if ($byte -gt 0x7F) {
            throw "A non-ASCII byte is not allowed: $($File.FullName)"
        }
    }
}

$assertPowerShellSyntax = {
    param(
        [Parameter(Mandatory = $true)]
        [System.IO.FileInfo]$File
    )

    $tokens = $null
    $parseErrors = $null
    $null = [System.Management.Automation.Language.Parser]::ParseFile(
        $File.FullName,
        [ref]$tokens,
        [ref]$parseErrors
    )

    if (@($parseErrors).Count -gt 0) {
        $messages = @($parseErrors | ForEach-Object { $_.Message }) -join [Environment]::NewLine
        throw "Windows PowerShell syntax errors were found in $($File.FullName):$([Environment]::NewLine)$messages"
    }
}

$assertFunctionFile = {
    param(
        [Parameter(Mandatory = $true)]
        [System.IO.FileInfo]$File
    )

    $tokens = $null
    $parseErrors = $null
    $ast = [System.Management.Automation.Language.Parser]::ParseFile(
        $File.FullName,
        [ref]$tokens,
        [ref]$parseErrors
    )
    $functionDefinitions = @(
        $ast.FindAll(
            {
                param($node)

                $node -is [System.Management.Automation.Language.FunctionDefinitionAst]
            },
            $true
        )
    )

    if ($functionDefinitions.Count -ne 1) {
        throw "A function source file must contain exactly one function: $($File.FullName)"
    }

    if ($functionDefinitions[0].Name -cne $File.BaseName) {
        throw "The function and file names must match: $($File.FullName)"
    }
}

$assertSource = {
    $requiredPaths = @(
        $moduleSourceDirectory
        (Join-Path -Path $moduleSourceDirectory -ChildPath 'Public')
        (Join-Path -Path $moduleSourceDirectory -ChildPath 'Private')
        $sourceManifestPath
        $buildConfigurationPath
        $formatterSettingsPath
        $analyzerSettingsPath
        $nativeProjectPath
        $testSupportProjectPath
    )
    foreach ($requiredPath in $requiredPaths) {
        if (-not (Test-Path -LiteralPath $requiredPath)) {
            throw "A required source path was not found: $requiredPath"
        }
    }

    $sourceModuleFiles = @(
        Get-ChildItem -LiteralPath $moduleSourceDirectory -Filter '*.psm1' -File -Recurse
    )
    if ($sourceModuleFiles.Count -gt 0) {
        throw 'Source .psm1 files are not allowed. ModuleBuilder must generate the script module.'
    }

    $sourceManifest = Import-PowerShellDataFile -Path $sourceManifestPath
    if ([string]$sourceManifest.PowerShellVersion -ne '5.1') {
        throw 'The source manifest must target Windows PowerShell 5.1.'
    }
    if ('Desktop' -notin @($sourceManifest.CompatiblePSEditions)) {
        throw 'The source manifest must target the Desktop edition.'
    }
    foreach ($emptyManifestKey in @('RequiredModules', 'FunctionsToExport', 'VariablesToExport', 'AliasesToExport')) {
        if (@($sourceManifest[$emptyManifestKey]).Count -gt 0) {
            throw "The source manifest value must be empty: $emptyManifestKey"
        }
    }

    $buildConfiguration = Import-PowerShellDataFile -Path $buildConfigurationPath
    foreach ($copyPath in @($buildConfiguration.CopyPaths)) {
        $resolvedCopyPath = Join-Path -Path $moduleSourceDirectory -ChildPath $copyPath
        if (-not (Test-Path -LiteralPath $resolvedCopyPath)) {
            throw "A ModuleBuilder CopyPaths entry does not exist: $resolvedCopyPath"
        }
    }

    $sourceFiles = @(& $getSourceFiles)
    foreach ($sourceFile in $sourceFiles) {
        & $assertAsciiFile -File $sourceFile
        & $assertPowerShellSyntax -File $sourceFile
    }

    foreach ($dotnetSourceFile in @(& $getDotnetSourceFiles)) {
        & $assertAsciiFile -File $dotnetSourceFile
    }

    $functionDirectories = @(
        (Join-Path -Path $moduleSourceDirectory -ChildPath 'Public')
        (Join-Path -Path $moduleSourceDirectory -ChildPath 'Private')
    )
    foreach ($functionDirectory in $functionDirectories) {
        $functionFiles = @(
            Get-ChildItem -LiteralPath $functionDirectory -Filter '*.ps1' -File
        )
        foreach ($functionFile in $functionFiles) {
            & $assertFunctionFile -File $functionFile
        }
    }
}

$invokeFormat = {
    param(
        [switch]$Check
    )

    $differentFiles = @()
    foreach ($sourceFile in @(& $getSourceFiles)) {
        $sourceText = [System.IO.File]::ReadAllText($sourceFile.FullName)
        $formattedText = Invoke-Formatter -ScriptDefinition $sourceText -Settings $formatterSettingsPath

        if ($Check) {
            if ($sourceText -cne $formattedText) {
                $differentFiles += $sourceFile.FullName
            }
            continue
        }

        [System.IO.File]::WriteAllText(
            $sourceFile.FullName,
            $formattedText,
            [System.Text.Encoding]::ASCII
        )
    }

    if ($differentFiles.Count -gt 0) {
        throw "PowerShell formatting differs in:$([Environment]::NewLine)$($differentFiles -join [Environment]::NewLine)"
    }
}

$invokeAnalyze = {
    $analysisResults = @()
    foreach ($sourceFile in @(& $getSourceFiles)) {
        $analysisResults += @(
            Invoke-ScriptAnalyzer -Path $sourceFile.FullName -Settings $analyzerSettingsPath
        )
    }

    if ($analysisResults.Count -gt 0) {
        $formattedResults = $analysisResults |
            Select-Object -Property ScriptName, Line, Column, Severity, RuleName, Message |
            Format-Table -AutoSize |
            Out-String
        throw "PSScriptAnalyzer reported findings:$([Environment]::NewLine)$formattedResults"
    }
}

$buildDotnetAssembly = {
    param(
        [Parameter(Mandatory = $true)]
        [string]$ProjectPath,

        [Parameter(Mandatory = $true)]
        [string]$TargetFramework,

        [Parameter(Mandatory = $true)]
        [string]$AssemblyFileName,

        [Parameter(Mandatory = $true)]
        [string]$DestinationDirectory
    )

    $dotnet = Get-Command -Name 'dotnet' -CommandType Application -ErrorAction Ignore
    if ($null -eq $dotnet) {
        throw 'Install the .NET SDK 8.0 or later. The dotnet command compiles the PSWinUtil assemblies.'
    }

    $projectName = [System.IO.Path]::GetFileNameWithoutExtension($ProjectPath)
    $intermediateDirectory = Join-Path `
        -Path $dotnetBuildDirectory `
        -ChildPath "$projectName/$TargetFramework"
    $previousErrorActionPreference = $ErrorActionPreference
    $ErrorActionPreference = 'Continue'
    try {
        $buildOutput = & $dotnet.Source build $ProjectPath `
            --configuration 'Release' `
            --framework $TargetFramework `
            --output $intermediateDirectory `
            --nologo 2>&1
    } finally {
        $ErrorActionPreference = $previousErrorActionPreference
    }

    if ($LASTEXITCODE -ne 0) {
        $buildMessage = @($buildOutput) -join [Environment]::NewLine
        throw "The dotnet build failed for $ProjectPath ($TargetFramework):$([Environment]::NewLine)$buildMessage"
    }

    $builtAssemblyPath = Join-Path -Path $intermediateDirectory -ChildPath $AssemblyFileName
    if (-not (Test-Path -LiteralPath $builtAssemblyPath -PathType Leaf)) {
        throw "The dotnet build did not generate an expected assembly: $builtAssemblyPath"
    }

    if (-not (Test-Path -LiteralPath $DestinationDirectory -PathType Container)) {
        $null = New-Item -Path $DestinationDirectory -ItemType 'Directory' -Force
    }

    Copy-Item -LiteralPath $builtAssemblyPath -Destination $DestinationDirectory -Force
}

$invokeBuild = {
    foreach ($staleDirectory in @($outputModuleDirectory, $outputTestSupportDirectory)) {
        if (Test-Path -LiteralPath $staleDirectory) {
            Remove-Item -LiteralPath $staleDirectory -Recurse -Force
        }
    }

    Build-Module -SourcePath $buildConfigurationPath | Out-Null

    foreach ($expectedPath in @($outputManifestPath, $outputModulePath)) {
        if (-not (Test-Path -LiteralPath $expectedPath -PathType Leaf)) {
            throw "ModuleBuilder did not generate an expected file: $expectedPath"
        }
    }

    & $buildDotnetAssembly `
        -ProjectPath $nativeProjectPath `
        -TargetFramework 'netstandard2.0' `
        -AssemblyFileName 'PSWinUtil.Native.dll' `
        -DestinationDirectory $outputLibraryDirectory

    foreach ($testSupportTargetFramework in @('net472', 'netstandard2.0')) {
        $testSupportDestination = Join-Path `
            -Path $outputTestSupportDirectory `
            -ChildPath $testSupportTargetFramework
        & $buildDotnetAssembly `
            -ProjectPath $testSupportProjectPath `
            -TargetFramework $testSupportTargetFramework `
            -AssemblyFileName 'PSWinUtil.TestSupport.dll' `
            -DestinationDirectory $testSupportDestination
    }

    $generatedPowerShellFiles = @(
        Get-ChildItem -LiteralPath $outputModuleDirectory -File -Recurse |
            Where-Object { $_.Extension -in @('.ps1', '.psd1', '.psm1', '.ps1xml') }
    )
    $utf8NoBom = [System.Text.UTF8Encoding]::new($false)
    foreach ($generatedPowerShellFile in $generatedPowerShellFiles) {
        $generatedPowerShellText = [System.IO.File]::ReadAllText($generatedPowerShellFile.FullName)
        $generatedPowerShellText = $generatedPowerShellText.Replace("`r`n", "`n").Replace("`r", "`n")
        [System.IO.File]::WriteAllText(
            $generatedPowerShellFile.FullName,
            $generatedPowerShellText,
            $utf8NoBom
        )
    }
}

$invokeImport = {
    if (-not (Test-Path -LiteralPath $outputManifestPath -PathType Leaf)) {
        throw "Build the module before importing it: $outputManifestPath"
    }

    Import-Module -Name $outputManifestPath -Force -Global -ErrorAction Stop
}

$assertOutput = {
    $outputFiles = @(
        Get-ChildItem -LiteralPath $outputModuleDirectory -File -Recurse |
            Where-Object { $_.Extension -in @('.ps1', '.psd1', '.psm1', '.ps1xml') }
    )
    foreach ($outputFile in $outputFiles) {
        & $assertAsciiFile -File $outputFile
        & $assertPowerShellSyntax -File $outputFile
    }

    $null = Test-ModuleManifest -Path $outputManifestPath -ErrorAction Stop
    $manifest = Import-PowerShellDataFile -Path $outputManifestPath
    $referenceKeys = @(
        'RootModule'
        'ScriptsToProcess'
        'TypesToProcess'
        'FormatsToProcess'
        'RequiredAssemblies'
    )
    foreach ($referenceKey in $referenceKeys) {
        if (-not $manifest.ContainsKey($referenceKey)) {
            continue
        }

        foreach ($referencePath in @($manifest[$referenceKey])) {
            if ([string]::IsNullOrWhiteSpace([string]$referencePath)) {
                continue
            }

            $resolvedReferencePath = Join-Path -Path $outputModuleDirectory -ChildPath $referencePath
            if (-not (Test-Path -LiteralPath $resolvedReferencePath -PathType Leaf)) {
                throw "The built manifest references a missing file: $resolvedReferencePath"
            }
        }
    }

    $windowsPowerShell = Get-Command -Name 'powershell.exe' -CommandType Application -ErrorAction Stop
    $escapedManifestPath = $outputManifestPath.Replace("'", "''")
    $importCommand = "Import-Module -Name '$escapedManifestPath' -Force -ErrorAction Stop"
    $cleanProcessOutput = & $windowsPowerShell.Source -NoProfile -NonInteractive -Command $importCommand 2>&1
    $exitCode = $LASTEXITCODE
    if ($exitCode -ne 0) {
        throw "A clean Windows PowerShell process could not import the module. Exit code: $exitCode$([Environment]::NewLine)$($cleanProcessOutput -join [Environment]::NewLine)"
    }
}

$invokeTest = {
    param(
        [Parameter(Mandatory = $true)]
        [ValidateSet('unit', 'integration', 'contract', 'all')]
        [string]$SelectedTestType,

        [switch]$SkipBuild
    )

    if (-not $SkipBuild) {
        & $invokeBuild
    }

    $testTypes = @($SelectedTestType)
    if ($SelectedTestType -eq 'all') {
        $testTypes = @('unit', 'integration', 'contract')
    }

    $testPaths = @(
        foreach ($targetTestType in $testTypes) {
            Join-Path -Path $repositoryRoot -ChildPath "tests/$targetTestType"
        }
    )
    $configuration = New-PesterConfiguration
    $configuration.Run.Path = $testPaths
    $configuration.Run.PassThru = $true
    $configuration.Output.Verbosity = 'Detailed'

    $testResult = Invoke-Pester -Configuration $configuration
    if ($null -eq $testResult -or $testResult.FailedCount -gt 0) {
        throw 'Pester reported one or more failed tests.'
    }
}

$invokeExternalCommand = {
    param(
        [Parameter(Mandatory = $true)]
        [string]$FilePath,

        [Parameter(Mandatory = $true)]
        [string[]]$ArgumentList
    )

    $previousErrorActionPreference = $ErrorActionPreference
    $ErrorActionPreference = 'Continue'
    try {
        $commandOutput = & $FilePath @ArgumentList 2>&1
    } finally {
        $ErrorActionPreference = $previousErrorActionPreference
    }

    if ($LASTEXITCODE -ne 0) {
        $commandLine = "$FilePath $($ArgumentList -join ' ')"
        $commandMessage = @($commandOutput) -join [Environment]::NewLine
        throw "The command failed: $commandLine$([Environment]::NewLine)$commandMessage"
    }

    @($commandOutput | ForEach-Object { $_.ToString() })
}

$getRequiredApplication = {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Name,

        [Parameter(Mandatory = $true)]
        [string]$Purpose
    )

    $application = Get-Command -Name $Name -CommandType Application -ErrorAction Ignore |
        Select-Object -First 1
    if ($null -eq $application) {
        throw "$Name was not found on PATH. $Purpose"
    }

    $application.Source
}

function Set-ReleaseVersion {
    [CmdletBinding(SupportsShouldProcess = $true)]
    param(
        [Parameter(Mandatory = $true)]
        [ValidatePattern('^(0|[1-9][0-9]*)\.(0|[1-9][0-9]*)\.(0|[1-9][0-9]*)$')]
        [string]$Version,

        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [string]$ManifestPath = $sourceManifestPath
    )

    $resolvedManifestPath = (Resolve-Path -LiteralPath $ManifestPath -ErrorAction Stop).Path
    $manifest = Import-PowerShellDataFile -LiteralPath $resolvedManifestPath
    if (-not $manifest.ContainsKey('ModuleVersion')) {
        throw "The module manifest does not define ModuleVersion: $resolvedManifestPath"
    }

    $currentVersion = [version][string]$manifest.ModuleVersion
    $releaseVersion = [version]$Version
    if ($releaseVersion -le $currentVersion) {
        throw "Release version $Version must be greater than the current version $currentVersion."
    }

    $manifestText = [System.IO.File]::ReadAllText($resolvedManifestPath)
    $versionPattern = [regex]::new(
        "(?m)^(?<Prefix>[ `t]*ModuleVersion[ `t]*=[ `t]*)'(?<Version>[^']+)'(?<Suffix>[ `t]*)$"
    )
    $versionMatches = $versionPattern.Matches($manifestText)
    if ($versionMatches.Count -ne 1) {
        throw "Expected exactly one single-quoted ModuleVersion entry: $resolvedManifestPath"
    }

    $updatedManifestText = $versionPattern.Replace(
        $manifestText,
        {
            param([System.Text.RegularExpressions.Match]$Match)

            $Match.Groups['Prefix'].Value + "'$Version'" + $Match.Groups['Suffix'].Value
        }
    )

    if ($PSCmdlet.ShouldProcess($resolvedManifestPath, "Set ModuleVersion to $Version")) {
        $manifestEncoding = [System.Text.UTF8Encoding]::new($false)
        [System.IO.File]::WriteAllText($resolvedManifestPath, $updatedManifestText, $manifestEncoding)
    }

    [pscustomobject]@{
        ManifestPath = $resolvedManifestPath
        PreviousVersion = $currentVersion.ToString()
        Version = $Version
    }
}

function Get-ReleaseIdentity {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$Branch,

        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [string]$ManifestPath = $sourceManifestPath,

        [Parameter()]
        [AllowEmptyCollection()]
        [string[]]$ExistingTagName = @()
    )

    $branchPattern = '^release/(?<Version>(0|[1-9][0-9]*)\.(0|[1-9][0-9]*)\.(0|[1-9][0-9]*))$'
    if ($Branch -notmatch $branchPattern) {
        throw "Invalid release branch: $Branch"
    }

    $version = $Matches['Version']
    $tagName = "v$version"

    $resolvedManifestPath = (Resolve-Path -LiteralPath $ManifestPath -ErrorAction Stop).Path
    $manifest = Import-PowerShellDataFile -LiteralPath $resolvedManifestPath
    if (-not $manifest.ContainsKey('ModuleVersion')) {
        throw "The module manifest does not define ModuleVersion: $resolvedManifestPath"
    }

    $manifestVersion = [string]$manifest.ModuleVersion
    if ($manifestVersion -ne $version) {
        throw "Release branch version $version does not match ModuleVersion $manifestVersion."
    }

    $releasedVersions = @(
        foreach ($existingTag in $ExistingTagName) {
            if ($existingTag -match '^v(?<Version>[0-9]+\.[0-9]+\.[0-9]+)$') {
                [version]$Matches['Version']
            }
        }
    )
    $latestReleasedVersion = $releasedVersions |
        Sort-Object -Descending |
        Select-Object -First 1
    if ($null -ne $latestReleasedVersion -and [version]$version -lt $latestReleasedVersion) {
        throw "Release version $version is older than existing tag v$latestReleasedVersion."
    }

    [pscustomobject]@{
        Version = $version
        TagName = $tagName
        ManifestPath = $resolvedManifestPath
    }
}

function Get-ReleasePublicationState {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$TagName,

        [Parameter(Mandatory = $true)]
        [string]$Version,

        [Parameter(Mandatory = $true)]
        [string]$ReleaseCommit,

        [Parameter()]
        [AllowEmptyString()]
        [string]$TagCommit = '',

        [switch]$GalleryExists,

        [switch]$GitHubReleaseExists
    )

    $tagExists = -not [string]::IsNullOrWhiteSpace($TagCommit)
    if ($tagExists -and $TagCommit -ne $ReleaseCommit) {
        throw "Tag $TagName does not point to release commit $ReleaseCommit."
    }

    if ($GalleryExists -and -not $tagExists) {
        throw "PowerShell Gallery version $Version exists without tag $TagName."
    }

    if ($GitHubReleaseExists -and (-not $tagExists -or -not $GalleryExists)) {
        throw "GitHub Release $TagName exists before its tag and Gallery publication are complete."
    }

    [pscustomobject]@{
        TagExists = $tagExists
        GalleryExists = [bool]$GalleryExists
        GitHubReleaseExists = [bool]$GitHubReleaseExists
    }
}

$invokeBump = {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Version
    )

    $result = Set-ReleaseVersion -Version $Version
    Write-Output -InputObject "ModuleVersion $($result.PreviousVersion) -> $($result.Version)"
    Write-Output -InputObject "Review the change, then run '.\dev.ps1 release'."
}

$invokeRelease = {
    $sourceManifest = Import-PowerShellDataFile -LiteralPath $sourceManifestPath
    $version = [string]$sourceManifest.ModuleVersion
    if ($version -notmatch '^(0|[1-9][0-9]*)\.(0|[1-9][0-9]*)\.(0|[1-9][0-9]*)$') {
        throw "The manifest must declare a major.minor.patch version before a release: $version"
    }

    $git = & $getRequiredApplication -Name 'git' -Purpose 'Git creates and pushes the release branch.'
    $gh = & $getRequiredApplication -Name 'gh' -Purpose 'The GitHub CLI opens the release pull request.'

    $tagName = "v$version"
    $branchName = "release/$version"

    $statusLines = @(
        & $invokeExternalCommand -FilePath $git -ArgumentList @('status', '--porcelain', '--untracked-files=no')
    )
    if ($statusLines.Count -eq 0) {
        throw "There is nothing to release. Run '.\dev.ps1 bump $version' first."
    }

    $manifestStatusPath = 'src/PSWinUtil/PSWinUtil.psd1'
    foreach ($statusLine in $statusLines) {
        $changedPath = $statusLine.Substring(3).Trim()
        if ($changedPath -ne $manifestStatusPath) {
            throw "A release changes only $manifestStatusPath. Commit or revert: $changedPath"
        }
    }

    $remoteTags = @(
        & $invokeExternalCommand -FilePath $git -ArgumentList @('ls-remote', '--tags', 'origin', "refs/tags/$tagName")
    )
    if ($remoteTags.Count -gt 0) {
        throw "The version was already released: $tagName"
    }

    $remoteBranches = @(
        & $invokeExternalCommand -FilePath $git -ArgumentList @('ls-remote', '--heads', 'origin', "refs/heads/$branchName")
    )
    if ($remoteBranches.Count -gt 0) {
        throw "The release branch already exists: $branchName"
    }

    $shouldProcessTarget = "$branchName and its pull request into master"
    $shouldProcessAction = 'Commit the version, push the branch, and open the release pull request'
    if (-not $PSCmdlet.ShouldProcess($shouldProcessTarget, $shouldProcessAction)) {
        return
    }

    $null = & $invokeExternalCommand -FilePath $git -ArgumentList @('switch', '--create', $branchName)
    $null = & $invokeExternalCommand -FilePath $git -ArgumentList @('add', '--', $manifestStatusPath)
    $null = & $invokeExternalCommand -FilePath $git -ArgumentList @('commit', '--message', "chore(release): $version")
    $null = & $invokeExternalCommand -FilePath $git -ArgumentList @('push', '--set-upstream', 'origin', $branchName)

    $pullRequestBody = @(
        '## Release'
        ''
        "- ModuleVersion: $version"
        "- Tag after merge: $tagName"
        '- Merging this pull request tags the merge commit, publishes to PowerShell Gallery, and publishes the GitHub Release.'
    ) -join [Environment]::NewLine

    $pullRequestArguments = @(
        'pr'
        'create'
        '--base'
        'master'
        '--head'
        $branchName
        '--title'
        "chore(release): $version"
        '--body'
        $pullRequestBody
    )
    $pullRequestOutput = @(
        & $invokeExternalCommand -FilePath $gh -ArgumentList $pullRequestArguments
    )
    foreach ($pullRequestLine in $pullRequestOutput) {
        Write-Output -InputObject $pullRequestLine
    }

    Write-Output -InputObject 'Approve and merge the pull request. The Release workflow does the rest.'
}

$invokeVerify = {
    & $importRequiredModule -Name 'PSScriptAnalyzer'
    & $importRequiredModule -Name 'ModuleBuilder'
    & $importRequiredModule -Name 'Pester'
    & $assertSource
    & $invokeFormat -Check
    & $invokeAnalyze
    & $invokeBuild
    & $assertOutput
    & $invokeTest -SelectedTestType 'all' -SkipBuild
}

switch ($Command) {
    'format' {
        & $assertSource
        & $importRequiredModule -Name 'PSScriptAnalyzer'
        & $invokeFormat
    }
    'analyze' {
        & $assertSource
        & $importRequiredModule -Name 'PSScriptAnalyzer'
        & $invokeAnalyze
    }
    'lint' {
        & $importRequiredModule -Name 'PSScriptAnalyzer'
        & $assertSource
        & $invokeFormat -Check
        & $invokeAnalyze
    }
    'build' {
        & $assertSource
        & $importRequiredModule -Name 'ModuleBuilder'
        & $invokeBuild
    }
    'import' {
        & $invokeImport
    }
    'test' {
        $selectedTestType = 'all'
        if (-not [string]::IsNullOrWhiteSpace($Argument)) {
            $selectedTestType = $Argument
        }
        if ($selectedTestType -notin @('unit', 'integration', 'contract', 'all')) {
            throw "The test command accepts unit, integration, contract, or all: $selectedTestType"
        }

        & $assertSource
        & $importRequiredModule -Name 'ModuleBuilder'
        & $importRequiredModule -Name 'Pester'
        & $invokeTest -SelectedTestType $selectedTestType
    }
    'verify' {
        & $invokeVerify
    }
    'ci' {
        & $invokeVerify
    }
    'bump' {
        if ([string]::IsNullOrWhiteSpace($Argument)) {
            throw 'The bump command requires a version. Example: .\dev.ps1 bump 1.2.3'
        }

        & $invokeBump -Version $Argument
    }
    'release' {
        & $invokeRelease
    }
}
