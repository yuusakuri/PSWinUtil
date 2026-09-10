[CmdletBinding(SupportsShouldProcess = $true)]
param(
    [Parameter(Position = 0)]
    [ValidateSet(
        'format', 'analyze', 'lint', 'build', 'import', 'test', 'verify', 'ci',
        'bump', 'release', 'docs', 'test-online-integration'
    )]
    [string]$Command,

    [Parameter(Position = 1)]
    [string]$Argument,

    [Parameter()]
    [string]$Branch
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
$commandReferencePath = Join-Path -Path $repositoryRoot -ChildPath 'docs/reference/commands.md'

function Write-DevUsage {
    Write-Output -InputObject @'
Usage:
  .\dev.ps1 format
  .\dev.ps1 analyze
  .\dev.ps1 lint
  .\dev.ps1 build
  .\dev.ps1 import
  .\dev.ps1 docs
  .\dev.ps1 docs check
  .\dev.ps1 test unit
  .\dev.ps1 test integration
  .\dev.ps1 test contract
  .\dev.ps1 test all
  .\dev.ps1 test-online-integration
  .\dev.ps1 verify
  .\dev.ps1 ci
  .\dev.ps1 bump 1.2.3
  .\dev.ps1 release <merge-commit> -Branch release/1.2.3
'@
}

$isDotSourced = $MyInvocation.InvocationName -eq '.'

if ([string]::IsNullOrWhiteSpace($Command) -and -not $isDotSourced) {
    Write-DevUsage
    exit 0
}

if (-not (Test-Path -LiteralPath $requirementsPath -PathType Leaf)) {
    throw "Development module requirements were not found: $requirementsPath"
}

$requirements = Import-PowerShellDataFile -Path $requirementsPath

function Import-RequiredModule {
    [CmdletBinding()]
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

function Test-WUCommand {
    [CmdletBinding()]
    [OutputType([bool])]
    param(
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$Name
    )

    [bool](Get-Command -Name $Name -ErrorAction Ignore)
}

function Assert-WUCommand {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$Name,

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$Purpose
    )

    if (-not (Test-WUCommand -Name $Name)) {
        throw "$Name was not found on PATH. $Purpose"
    }
}

function Get-DevSourceFile {
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

function Get-DevDotnetSourceFile {
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

function Assert-DevAsciiFile {
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

function Assert-DevPowerShellSyntax {
    param(
        [Parameter(Mandatory = $true)]
        [System.IO.FileInfo]$File
    )

    $tokens = $null
    $parseErrors = $null
    [System.Management.Automation.Language.Parser]::ParseFile(
        $File.FullName,
        [ref]$tokens,
        [ref]$parseErrors
    ) | Out-Null

    if (@($parseErrors).Count -gt 0) {
        $messages = @($parseErrors | ForEach-Object { $_.Message }) -join [Environment]::NewLine
        throw "Windows PowerShell syntax errors were found in $($File.FullName):$([Environment]::NewLine)$messages"
    }
}

function Assert-DevFunctionFile {
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

function Assert-DevSource {
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

    $sourceFiles = @(Get-DevSourceFile)
    foreach ($sourceFile in $sourceFiles) {
        Assert-DevAsciiFile -File $sourceFile
        Assert-DevPowerShellSyntax -File $sourceFile
    }

    foreach ($dotnetSourceFile in @(Get-DevDotnetSourceFile)) {
        Assert-DevAsciiFile -File $dotnetSourceFile
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
            Assert-DevFunctionFile -File $functionFile
        }
    }
}

function Invoke-DevFormat {
    param(
        [switch]$Check
    )

    $differentFiles = @()
    foreach ($sourceFile in @(Get-DevSourceFile)) {
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

function Invoke-DevAnalyze {
    $analysisResults = @()
    foreach ($sourceFile in @(Get-DevSourceFile)) {
        $analysisResults += @(
            Invoke-ScriptAnalyzer -Path $sourceFile.FullName -Settings $analyzerSettingsPath
        )
    }

    if ($analysisResults.Count -gt 0) {
        $formattedResults = @(
            $analysisResults | ForEach-Object {
                '{0}:{1}:{2}: {3} {4}: {5}' -f
                $_.ScriptPath, $_.Line, $_.Column, $_.Severity, $_.RuleName, $_.Message
            }
        ) -join [Environment]::NewLine
        throw "PSScriptAnalyzer reported findings:$([Environment]::NewLine)$formattedResults"
    }
}

function Publish-DevDotnetAssembly {
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

    Assert-WUCommand `
        -Name 'dotnet' `
        -Purpose 'Install the .NET SDK 8.0 or later. The dotnet command compiles the PSWinUtil assemblies.'

    $projectName = [System.IO.Path]::GetFileNameWithoutExtension($ProjectPath)
    $intermediateDirectory = Join-Path `
        -Path $dotnetBuildDirectory `
        -ChildPath "$projectName/$TargetFramework"
    $previousErrorActionPreference = $ErrorActionPreference
    $ErrorActionPreference = 'Continue'
    try {
        $buildOutput = & 'dotnet' build $ProjectPath `
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
        New-Item -Path $DestinationDirectory -ItemType 'Directory' -Force | Out-Null
    }

    Copy-Item -LiteralPath $builtAssemblyPath -Destination $DestinationDirectory -Force
}

function Invoke-DevBuild {
    foreach ($staleDirectory in @($outputModuleDirectory, $outputTestSupportDirectory)) {
        if (Test-Path -LiteralPath $staleDirectory) {
            Remove-Item -LiteralPath $staleDirectory -Recurse -Force
        }
    }

    $sourceManifest = Import-PowerShellDataFile -LiteralPath $sourceManifestPath
    $sourceReleaseVersion = Get-ReleaseManifestVersion -Manifest $sourceManifest
    Build-Module -SourcePath $buildConfigurationPath -SemVer $sourceReleaseVersion | Out-Null

    foreach ($expectedPath in @($outputManifestPath, $outputModulePath)) {
        if (-not (Test-Path -LiteralPath $expectedPath -PathType Leaf)) {
            throw "ModuleBuilder did not generate an expected file: $expectedPath"
        }
    }

    Publish-DevDotnetAssembly `
        -ProjectPath $nativeProjectPath `
        -TargetFramework 'netstandard2.0' `
        -AssemblyFileName 'PSWinUtil.Native.dll' `
        -DestinationDirectory $outputLibraryDirectory

    foreach ($testSupportTargetFramework in @('net472', 'netstandard2.0')) {
        $testSupportDestination = Join-Path `
            -Path $outputTestSupportDirectory `
            -ChildPath $testSupportTargetFramework
        Publish-DevDotnetAssembly `
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

function Invoke-DevImport {
    if (-not (Test-Path -LiteralPath $outputManifestPath -PathType Leaf)) {
        throw "Build the module before importing it: $outputManifestPath"
    }

    Import-Module -Name $outputManifestPath -Force -Global -ErrorAction Stop
}

function Assert-DevOutput {
    $outputFiles = @(
        Get-ChildItem -LiteralPath $outputModuleDirectory -File -Recurse |
            Where-Object { $_.Extension -in @('.ps1', '.psd1', '.psm1', '.ps1xml') }
    )
    foreach ($outputFile in $outputFiles) {
        Assert-DevAsciiFile -File $outputFile
        Assert-DevPowerShellSyntax -File $outputFile
    }

    Test-ModuleManifest -Path $outputManifestPath -ErrorAction Stop | Out-Null
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

    $escapedManifestPath = $outputManifestPath.Replace("'", "''")
    $importCommand = "Import-Module -Name '$escapedManifestPath' -Force -ErrorAction Stop"
    $cleanProcessOutput = & 'powershell.exe' -NoProfile -NonInteractive -Command $importCommand 2>&1
    $exitCode = $LASTEXITCODE
    if ($exitCode -ne 0) {
        throw "A clean Windows PowerShell process could not import the module. Exit code: $exitCode$([Environment]::NewLine)$($cleanProcessOutput -join [Environment]::NewLine)"
    }
}

function Invoke-DevTest {
    param(
        [Parameter(Mandatory = $true)]
        [ValidateSet('unit', 'integration', 'contract', 'all')]
        [string]$SelectedTestType,

        [switch]$SkipBuild
    )

    if (-not $SkipBuild) {
        Invoke-DevBuild
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
    $configuration.Filter.ExcludeTag = @('Online')

    $testResult = Invoke-Pester -Configuration $configuration
    if (
        $null -eq $testResult -or
        $testResult.FailedCount -gt 0 -or
        $testResult.FailedContainersCount -gt 0
    ) {
        throw 'Pester reported one or more failed tests.'
    }
}

function Invoke-DevOnlineIntegrationTest {
    Invoke-DevBuild

    $onlineIntegrationTests = @(
        Get-ChildItem `
            -LiteralPath (Join-Path -Path $repositoryRoot -ChildPath 'tests') `
            -File `
            -Recurse `
            -Filter '*.OnlineIntegration.Tests.ps1'
    )
    if ($onlineIntegrationTests.Count -eq 0) {
        throw 'No online integration tests were found.'
    }

    $configuration = New-PesterConfiguration
    $configuration.Run.Path = @($onlineIntegrationTests.FullName)
    $configuration.Run.PassThru = $true
    $configuration.Output.Verbosity = 'Detailed'
    $configuration.Filter.Tag = @('Online')

    $testResult = Invoke-Pester -Configuration $configuration
    if (
        $null -eq $testResult -or
        $testResult.FailedCount -gt 0 -or
        $testResult.FailedContainersCount -gt 0
    ) {
        throw 'Pester reported one or more failed online integration tests.'
    }
}

function Get-CommandReference {
    [CmdletBinding()]
    [OutputType([string])]
    param(
        [Parameter(Mandatory = $true)]
        [string]$ManifestPath
    )

    $moduleName = [System.IO.Path]::GetFileNameWithoutExtension($ManifestPath)
    Get-Module -Name $moduleName -All | Remove-Module -Force
    $module = Import-Module -Name $ManifestPath -Force -PassThru -ErrorAction Stop
    $commands = @(
        Get-Command -Module $module.Name |
            Where-Object {
                $_.Module.Path -eq $module.Path -and
                $module.ExportedCommands.ContainsKey($_.Name)
            }
    )
    if ($commands.Count -eq 0) {
        throw "The built module exports no commands: $ManifestPath"
    }

    $commandNames = [string[]]@($commands.Name)
    [System.Array]::Sort($commandNames, [System.StringComparer]::Ordinal)
    $lines = @(
        '# Command reference'
        ''
        'The following table is generated from the exported commands and their comment-based help.'
        ''
        '| Command | Synopsis |'
        '| --- | --- |'
        foreach ($commandName in $commandNames) {
            $help = Get-Help -Name "$($module.Name)\$commandName" -ErrorAction Stop
            $synopsis = [string]$help.Synopsis
            if (
                [string]::IsNullOrWhiteSpace($synopsis) -or
                $help.PSObject.TypeNames -notcontains 'MamlCommandHelpInfo'
            ) {
                throw "Comment-based Synopsis is required for $commandName."
            }

            $cell = [System.Net.WebUtility]::HtmlEncode($synopsis.Trim())
            $cell = $cell.Replace('\', '\\').Replace('`', '\`').Replace('|', '&#124;')
            $cell = $cell -replace '\r\n|\r|\n', '<br>'
            '| `{0}` | {1} |' -f $commandName, $cell
        }
        ''
        'Read the complete help for a command with:'
        ''
        '```powershell'
        "Get-Help -Name '<CommandName>' -Full"
        '```'
        ''
        'Find commands by name with:'
        ''
        '```powershell'
        "Get-Command -Module 'PSWinUtil' -Name '*Android*'"
        '```'
        ''
    )

    $lines -join "`n"
}

function Update-CommandReference {
    [CmdletBinding(SupportsShouldProcess = $true)]
    param(
        [Parameter(Mandatory = $true)]
        [string]$ManifestPath,

        [Parameter(Mandatory = $true)]
        [string]$Path,

        [Parameter()]
        [switch]$Check
    )

    $reference = Get-CommandReference -ManifestPath $ManifestPath
    $expectedBytes = [System.Text.UTF8Encoding]::new($false).GetBytes($reference)
    if ($Check) {
        if (-not [System.IO.File]::Exists($Path)) {
            throw "docs/reference/commands.md is out of date. Run '.\dev.ps1 docs' and commit the generated file."
        }

        $actualBytes = [System.IO.File]::ReadAllBytes($Path)
        if (-not [System.Linq.Enumerable]::SequenceEqual($expectedBytes, $actualBytes)) {
            throw "docs/reference/commands.md is out of date. Run '.\dev.ps1 docs' and commit the generated file."
        }
        return
    }

    if ($PSCmdlet.ShouldProcess($Path, 'Write the generated command reference')) {
        [System.IO.Directory]::CreateDirectory([System.IO.Path]::GetDirectoryName($Path)) | Out-Null
        [System.IO.File]::WriteAllBytes($Path, $expectedBytes)
    }
}

function Invoke-ExternalCommand {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$FilePath,

        [Parameter(Mandatory = $true)]
        [string[]]$ArgumentList,

        [Parameter()]
        [string]$WorkingDirectory = $repositoryRoot
    )

    $previousErrorActionPreference = $ErrorActionPreference
    Push-Location -LiteralPath $WorkingDirectory
    try {
        $ErrorActionPreference = 'Continue'
        $commandOutput = & $FilePath @ArgumentList 2>&1
        $exitCode = $LASTEXITCODE
    } finally {
        $ErrorActionPreference = $previousErrorActionPreference
        Pop-Location
    }

    if ($exitCode -ne 0) {
        $commandLine = "$FilePath $($ArgumentList -join ' ')"
        $commandMessage = @($commandOutput) -join [Environment]::NewLine
        throw "The command failed: $commandLine$([Environment]::NewLine)$commandMessage"
    }

    @($commandOutput | ForEach-Object { $_.ToString() })
}

function Get-RequiredApplication {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$Name,

        [Parameter(Mandatory = $true)]
        [string]$Purpose
    )

    Assert-WUCommand -Name $Name -Purpose $Purpose

    $Name
}

function ConvertTo-ReleaseVersion {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$Version
    )

    $versionPattern = '^(?<Base>(0|[1-9][0-9]*)\.(0|[1-9][0-9]*)\.(0|[1-9][0-9]*))(?:-(?<Prerelease>[0-9A-Za-z]+))?$'
    if ($Version -notmatch $versionPattern) {
        throw "Invalid release version: $Version"
    }

    [pscustomobject]@{
        BaseVersion = [version]$Matches['Base']
        Prerelease = [string]$Matches['Prerelease']
        Version = $Version
    }
}

function Compare-ReleaseVersion {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$ReferenceVersion,

        [Parameter(Mandatory = $true)]
        [string]$DifferenceVersion
    )

    $reference = ConvertTo-ReleaseVersion -Version $ReferenceVersion
    $difference = ConvertTo-ReleaseVersion -Version $DifferenceVersion
    $baseComparison = $reference.BaseVersion.CompareTo($difference.BaseVersion)
    if ($baseComparison -ne 0) {
        return [Math]::Sign($baseComparison)
    }

    $referenceIsStable = [string]::IsNullOrWhiteSpace($reference.Prerelease)
    $differenceIsStable = [string]::IsNullOrWhiteSpace($difference.Prerelease)
    if ($referenceIsStable -and $differenceIsStable) {
        return 0
    }
    if ($referenceIsStable) {
        return 1
    }
    if ($differenceIsStable) {
        return -1
    }

    [Math]::Sign([string]::Compare(
            $reference.Prerelease,
            $difference.Prerelease,
            [System.StringComparison]::OrdinalIgnoreCase
        ))
}

function Get-ReleaseManifestVersion {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [object]$Manifest
    )

    $moduleVersion = ''
    $privateData = $null
    if ($Manifest -is [System.Collections.IDictionary]) {
        if (-not $Manifest.Contains('ModuleVersion')) {
            throw 'The module manifest does not define ModuleVersion.'
        }
        $moduleVersion = [string]$Manifest['ModuleVersion']
        $privateData = $Manifest['PrivateData']
    } else {
        $moduleVersionProperty = $Manifest.PSObject.Properties['ModuleVersion']
        if ($null -eq $moduleVersionProperty) {
            $moduleVersionProperty = $Manifest.PSObject.Properties['Version']
        }
        if ($null -eq $moduleVersionProperty) {
            throw 'The module manifest does not define ModuleVersion.'
        }
        $moduleVersion = [string]$moduleVersionProperty.Value
        $privateDataProperty = $Manifest.PSObject.Properties['PrivateData']
        if ($null -ne $privateDataProperty) {
            $privateData = $privateDataProperty.Value
        }
    }

    $prerelease = ''
    if ($privateData -is [System.Collections.IDictionary] -and $privateData.Contains('PSData')) {
        $psData = $privateData['PSData']
        if ($psData -is [System.Collections.IDictionary] -and $psData.Contains('Prerelease')) {
            $prerelease = [string]$psData['Prerelease']
        }
    }

    $version = $moduleVersion
    if (-not [string]::IsNullOrWhiteSpace($prerelease)) {
        $version = "$moduleVersion-$prerelease"
    }
    (ConvertTo-ReleaseVersion -Version $version).Version
}

function Set-ReleaseVersion {
    [CmdletBinding(SupportsShouldProcess = $true)]
    param(
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
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

    $currentVersion = Get-ReleaseManifestVersion -Manifest $manifest
    $releaseVersion = ConvertTo-ReleaseVersion -Version $Version
    if ((Compare-ReleaseVersion -ReferenceVersion $Version -DifferenceVersion $currentVersion) -le 0) {
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

    $prereleasePattern = [regex]::new(
        "(?m)^(?<Prefix>[ `t]*Prerelease[ `t]*=[ `t]*)'(?<Prerelease>[^']*)'(?<Suffix>[ `t]*)$"
    )
    $prereleaseMatches = $prereleasePattern.Matches($manifestText)
    if ($prereleaseMatches.Count -ne 1) {
        throw "Expected exactly one single-quoted Prerelease entry: $resolvedManifestPath"
    }

    $updatedManifestText = $versionPattern.Replace(
        $manifestText,
        {
            param([System.Text.RegularExpressions.Match]$Match)

            $Match.Groups['Prefix'].Value + "'$($releaseVersion.BaseVersion)'" + $Match.Groups['Suffix'].Value
        }
    )
    $updatedManifestText = $prereleasePattern.Replace(
        $updatedManifestText,
        {
            param([System.Text.RegularExpressions.Match]$Match)

            $Match.Groups['Prefix'].Value + "'$($releaseVersion.Prerelease)'" + $Match.Groups['Suffix'].Value
        }
    )

    if ($PSCmdlet.ShouldProcess($resolvedManifestPath, "Set release version to $Version")) {
        $manifestEncoding = [System.Text.UTF8Encoding]::new($false)
        [System.IO.File]::WriteAllText($resolvedManifestPath, $updatedManifestText, $manifestEncoding)
    }

    [pscustomobject]@{
        ManifestPath = $resolvedManifestPath
        PreviousVersion = $currentVersion
        Version = $Version
    }
}

function Get-ReleaseIdentity {
    [CmdletBinding(DefaultParameterSetName = 'ManifestPath')]
    param(
        [Parameter(Mandatory = $true)]
        [string]$Branch,

        [Parameter(ParameterSetName = 'ManifestPath')]
        [ValidateNotNullOrEmpty()]
        [string]$ManifestPath = $sourceManifestPath,

        [Parameter(Mandatory = $true, ParameterSetName = 'ManifestVersion')]
        [ValidateNotNullOrEmpty()]
        [string]$ManifestVersion,

        [Parameter()]
        [AllowEmptyCollection()]
        [string[]]$ExistingTagName = @()
    )

    $branchPattern = '^release/(?<Version>(0|[1-9][0-9]*)\.(0|[1-9][0-9]*)\.(0|[1-9][0-9]*)(-[0-9A-Za-z]+)?)$'
    if ($Branch -notmatch $branchPattern) {
        throw "Invalid release branch: $Branch"
    }

    $version = $Matches['Version']
    $tagName = "v$version"

    $resolvedManifestPath = ''
    if ($PSCmdlet.ParameterSetName -eq 'ManifestPath') {
        $resolvedManifestPath = (Resolve-Path -LiteralPath $ManifestPath -ErrorAction Stop).Path
        $manifest = Import-PowerShellDataFile -LiteralPath $resolvedManifestPath
        if (-not $manifest.ContainsKey('ModuleVersion')) {
            throw "The module manifest does not define ModuleVersion: $resolvedManifestPath"
        }

        $ManifestVersion = Get-ReleaseManifestVersion -Manifest $manifest
    }

    if ($manifestVersion -ne $version) {
        throw "Release branch version $version does not match manifest version $manifestVersion."
    }

    $latestReleasedVersion = $null
    foreach ($existingTag in $ExistingTagName) {
        if (
            $existingTag -notmatch `
                '^v(?<Version>(0|[1-9][0-9]*)\.(0|[1-9][0-9]*)\.(0|[1-9][0-9]*)(-[0-9A-Za-z]+)?)$'
        ) {
            continue
        }

        $existingVersion = $Matches['Version']
        if (
            $null -eq $latestReleasedVersion -or
            (Compare-ReleaseVersion `
                -ReferenceVersion $existingVersion `
                -DifferenceVersion $latestReleasedVersion) -gt 0
        ) {
            $latestReleasedVersion = $existingVersion
        }
    }
    if (
        $null -ne $latestReleasedVersion -and
        (Compare-ReleaseVersion `
            -ReferenceVersion $version `
            -DifferenceVersion $latestReleasedVersion) -lt 0
    ) {
        throw "Release version $version is older than existing tag v$latestReleasedVersion."
    }

    $parsedVersion = ConvertTo-ReleaseVersion -Version $version
    [pscustomobject]@{
        Version = $version
        TagName = $tagName
        ManifestPath = $resolvedManifestPath
        Prerelease = $parsedVersion.Prerelease
        IsPrerelease = -not [string]::IsNullOrWhiteSpace($parsedVersion.Prerelease)
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

function Invoke-Bump {
    [CmdletBinding(SupportsShouldProcess = $true)]
    param(
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$Version
    )

    ConvertTo-ReleaseVersion -Version $Version | Out-Null
    $tagName = "v$Version"
    $branchName = "release/$Version"
    $manifestStatusPath = 'src/PSWinUtil/PSWinUtil.psd1'
    $manifest = Import-PowerShellDataFile -LiteralPath $sourceManifestPath
    $currentVersion = Get-ReleaseManifestVersion -Manifest $manifest
    if ((Compare-ReleaseVersion -ReferenceVersion $Version -DifferenceVersion $currentVersion) -le 0) {
        throw "Release version $Version must be greater than the current version $currentVersion."
    }

    $git = Get-RequiredApplication -Name 'git' -Purpose 'Git creates and pushes the release branch.'
    $gh = Get-RequiredApplication -Name 'gh' -Purpose 'The GitHub CLI opens the release pull request.'

    $statusLines = @(
        Invoke-ExternalCommand -FilePath $git -ArgumentList @('status', '--porcelain', '--untracked-files=no')
    )
    if ($statusLines.Count -gt 0) {
        throw "Commit or revert the working tree before preparing a release: $($statusLines -join ', ')"
    }

    $remoteTags = @(
        Invoke-ExternalCommand -FilePath $git -ArgumentList @('ls-remote', '--tags', 'origin', "refs/tags/$tagName")
    )
    if ($remoteTags.Count -gt 0) {
        throw "The version was already released: $tagName"
    }

    $remoteBranches = @(
        Invoke-ExternalCommand -FilePath $git -ArgumentList @('ls-remote', '--heads', 'origin', "refs/heads/$branchName")
    )
    if ($remoteBranches.Count -gt 0) {
        throw "The release branch already exists: $branchName"
    }

    $shouldProcessTarget = "$branchName and its pull request into master"
    $shouldProcessAction = "Set release version to $Version, push the branch, and open the pull request"
    if (-not $PSCmdlet.ShouldProcess($shouldProcessTarget, $shouldProcessAction)) {
        return
    }

    $result = Set-ReleaseVersion -Version $Version
    Write-Output -InputObject "Release version $($result.PreviousVersion) -> $($result.Version)"

    Invoke-ExternalCommand -FilePath $git -ArgumentList @('switch', '--create', $branchName) | Out-Null
    Invoke-ExternalCommand -FilePath $git -ArgumentList @('add', '--', $manifestStatusPath) | Out-Null
    Invoke-ExternalCommand -FilePath $git -ArgumentList @('commit', '--message', "chore(release): $Version") | Out-Null
    Invoke-ExternalCommand -FilePath $git -ArgumentList @('push', '--set-upstream', 'origin', $branchName) | Out-Null

    $pullRequestBody = @(
        '## Release'
        ''
        "- Version: $Version"
        "- Tag after merge: $tagName"
        '- Merging this pull request tags the merge commit, publishes to PowerShell Gallery, and publishes the GitHub Release.'
    ) -join [Environment]::NewLine

    $pullRequestOutput = @(
        Invoke-ExternalCommand -FilePath $gh -ArgumentList @(
            'pr'
            'create'
            '--base'
            'master'
            '--head'
            $branchName
            '--title'
            "chore(release): $Version"
            '--body'
            $pullRequestBody
        )
    )
    foreach ($pullRequestLine in $pullRequestOutput) {
        Write-Output -InputObject $pullRequestLine
    }

    Write-Output -InputObject 'Approve and merge the pull request to publish the release.'
}

function Invoke-Release {
    [CmdletBinding(SupportsShouldProcess = $true)]
    param(
        [Parameter(Mandatory = $true)]
        [ValidatePattern('^[0-9a-fA-F]{40}$')]
        [string]$ReleaseCommit,

        [Parameter(Mandatory = $true)]
        [string]$Branch
    )

    $git = Get-RequiredApplication -Name 'git' -Purpose 'Git inspects the release commit and tags.'
    Invoke-ExternalCommand -FilePath $git -ArgumentList @(
        'fetch', 'origin', '+refs/heads/master:refs/remotes/origin/master', '--tags'
    ) | Out-Null

    Invoke-ExternalCommand -FilePath $git -ArgumentList @('cat-file', '-e', "$ReleaseCommit^{commit}") | Out-Null
    $headOutput = @(Invoke-ExternalCommand -FilePath $git -ArgumentList @('rev-parse', 'HEAD'))
    $headCommit = ($headOutput -join '').Trim()
    if ($headCommit -ne $ReleaseCommit) {
        throw "Checked out commit $headCommit does not match release commit $ReleaseCommit."
    }

    $statusLines = @(
        Invoke-ExternalCommand -FilePath $git -ArgumentList @('status', '--porcelain', '--untracked-files=no')
        Invoke-ExternalCommand -FilePath $git -ArgumentList @('ls-files', '--others', '--exclude-standard', '--', 'src')
    )
    if ($statusLines.Count -gt 0) {
        throw 'The release checkout contains uncommitted changes. Build and publish the committed source.'
    }

    Invoke-ExternalCommand -FilePath $git -ArgumentList @(
        'merge-base', '--is-ancestor', $ReleaseCommit, 'origin/master'
    ) | Out-Null

    $manifest = Get-ReleaseManifest -GitPath $git -ReleaseCommit $ReleaseCommit
    $manifestVersion = Get-ReleaseManifestVersion -Manifest $manifest
    $existingTagNames = @(Invoke-ExternalCommand -FilePath $git -ArgumentList @('tag', '--list', 'v*'))
    $identity = Get-ReleaseIdentity `
        -Branch $Branch `
        -ManifestVersion $manifestVersion `
        -ExistingTagName $existingTagNames
    $state = Get-RemoteReleaseState `
        -ReleaseCommit $ReleaseCommit `
        -Version $identity.Version

    Invoke-ReleasePublish `
        -ReleaseCommit $ReleaseCommit `
        -Version $identity.Version `
        -State $state `
        -ModuleDirectory $outputModuleDirectory `
        -ArtifactPath (Join-Path -Path $repositoryRoot -ChildPath "PSWinUtil-$($identity.Version).zip")
}

function Get-ReleaseManifest {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$GitPath,

        [Parameter(Mandatory = $true)]
        [ValidatePattern('^[0-9a-fA-F]{40}$')]
        [string]$ReleaseCommit
    )

    $manifestLines = @(Invoke-ExternalCommand -FilePath $GitPath -ArgumentList @(
            'show', "${ReleaseCommit}:src/PSWinUtil/PSWinUtil.psd1"
        ))
    $tokens = $null
    $parseErrors = $null
    $ast = [System.Management.Automation.Language.Parser]::ParseInput(
        ($manifestLines -join "`n"), [ref]$tokens, [ref]$parseErrors
    )
    if (@($parseErrors).Count -gt 0) {
        throw "The manifest at release commit $ReleaseCommit contains syntax errors."
    }

    $ast.GetScriptBlock().CheckRestrictedLanguage([string[]]@(), [string[]]@(), $false)
    if (@($ast.EndBlock.Statements).Count -ne 1) {
        throw "The manifest at release commit $ReleaseCommit must contain one data table."
    }
    $manifestStatement = $ast.EndBlock.Statements | Select-Object -First 1
    if (
        $manifestStatement -isnot [System.Management.Automation.Language.PipelineAst] -or
        $manifestStatement.PipelineElements.Count -ne 1 -or
        $manifestStatement.PipelineElements[0] -isnot [System.Management.Automation.Language.CommandExpressionAst] -or
        $manifestStatement.PipelineElements[0].Expression -isnot [System.Management.Automation.Language.HashtableAst]
    ) {
        throw "The manifest at release commit $ReleaseCommit must contain one data table."
    }
    $manifest = $manifestStatement.PipelineElements[0].Expression.SafeGetValue()
    if ($manifest -isnot [hashtable] -or -not $manifest.ContainsKey('ModuleVersion')) {
        throw "The manifest at release commit $ReleaseCommit does not define ModuleVersion."
    }

    $manifest
}

function Test-GalleryPublication {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$Version
    )

    $parsedVersion = ConvertTo-ReleaseVersion -Version $Version
    $findParameters = @{
        Name = 'PSWinUtil'
        Version = "[$Version]"
        Repository = 'PSGallery'
        ErrorAction = 'Stop'
    }
    if (-not [string]::IsNullOrWhiteSpace($parsedVersion.Prerelease)) {
        $findParameters.Prerelease = $true
    }

    try {
        $resource = Find-PSResource @findParameters
    } catch {
        if ($_.FullyQualifiedErrorId -eq 'PackageNotFound,Microsoft.PowerShell.PSResourceGet.Cmdlets.FindPSResource') {
            return $false
        }

        throw
    }

    $null -ne $resource
}

function Test-GitHubRelease {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$GhPath,

        [Parameter(Mandatory = $true)]
        [string]$TagName,

        [Parameter()]
        [switch]$Prerelease
    )

    $releaseJson = @(Invoke-ExternalCommand -FilePath $GhPath -ArgumentList @(
            'api', '--paginate', '--slurp', 'repos/{owner}/{repo}/releases?per_page=100'
        )) -join "`n"
    $releasePages = ConvertFrom-Json -InputObject $releaseJson -ErrorAction Stop
    foreach ($page in $releasePages) {
        foreach ($release in $page) {
            if ($release.tag_name -eq $TagName) {
                if ($release.draft) {
                    throw "GitHub Release $TagName is a draft. Publish or remove the draft before retrying."
                }
                $prereleaseProperty = $release.PSObject.Properties['prerelease']
                $releaseIsPrerelease = $null -ne $prereleaseProperty -and [bool]$prereleaseProperty.Value
                if ($releaseIsPrerelease -ne [bool]$Prerelease) {
                    throw "GitHub Release $TagName has an incorrect prerelease state."
                }

                return $true
            }
        }
    }

    $false
}

function Get-RemoteReleaseState {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$ReleaseCommit,

        [Parameter(Mandatory = $true)]
        [string]$Version
    )

    $tagName = "v$Version"
    $parsedVersion = ConvertTo-ReleaseVersion -Version $Version
    $isPrerelease = -not [string]::IsNullOrWhiteSpace($parsedVersion.Prerelease)
    $git = Get-RequiredApplication -Name 'git' -Purpose 'Git reports whether the release tag exists.'
    $gh = Get-RequiredApplication -Name 'gh' -Purpose 'The GitHub CLI reports whether the release exists.'

    $remoteTagLines = @(Invoke-ExternalCommand -FilePath $git -ArgumentList @(
            'ls-remote', '--tags', 'origin', "refs/tags/$tagName", "refs/tags/$tagName^{}"
        ))
    $tagCommit = ''
    foreach ($line in $remoteTagLines) {
        $parts = $line -split '\s+', 2
        if ($parts[1] -eq "refs/tags/$tagName^{}") {
            $tagCommit = $parts[0]
            break
        }
        $tagCommit = $parts[0]
    }

    Import-RequiredModule -Name 'Microsoft.PowerShell.PSResourceGet'
    $galleryExists = Test-GalleryPublication -Version $Version
    $gitHubReleaseExists = Test-GitHubRelease `
        -GhPath $gh `
        -TagName $tagName `
        -Prerelease:$isPrerelease

    Get-ReleasePublicationState `
        -TagName $tagName `
        -Version $Version `
        -ReleaseCommit $ReleaseCommit `
        -TagCommit $tagCommit `
        -GalleryExists:$galleryExists `
        -GitHubReleaseExists:$gitHubReleaseExists
}

function Invoke-ReleasePack {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$ModuleDirectory,

        [Parameter(Mandatory = $true)]
        [string]$ArtifactPath
    )

    if (Test-Path -LiteralPath $ArtifactPath) {
        Remove-Item -LiteralPath $ArtifactPath -Force
    }

    Compress-Archive `
        -LiteralPath $ModuleDirectory `
        -DestinationPath $ArtifactPath `
        -CompressionLevel Optimal
}

function Invoke-ReleasePublish {
    [CmdletBinding(SupportsShouldProcess = $true)]
    param(
        [Parameter(Mandatory = $true)]
        [string]$ReleaseCommit,

        [Parameter(Mandatory = $true)]
        [string]$Version,

        [Parameter(Mandatory = $true)]
        [psobject]$State,

        [Parameter(Mandatory = $true)]
        [string]$ModuleDirectory,

        [Parameter(Mandatory = $true)]
        [string]$ArtifactPath
    )

    $tagName = "v$Version"
    if ($State.GitHubReleaseExists) {
        return [pscustomobject]@{
            Version = $Version
            TagName = $tagName
            ArtifactPath = ''
        }
    }

    $manifestPath = Join-Path -Path $ModuleDirectory -ChildPath 'PSWinUtil.psd1'
    if (-not (Test-Path -LiteralPath $manifestPath -PathType Leaf)) {
        throw "Build the module before publishing a release: $ModuleDirectory"
    }

    $builtManifest = Test-ModuleManifest -Path $manifestPath -ErrorAction Stop
    $builtVersion = Get-ReleaseManifestVersion -Manifest $builtManifest
    if ($builtVersion -ne $Version) {
        throw "Built version $builtVersion does not match the release version $Version."
    }

    $git = Get-RequiredApplication -Name 'git' -Purpose 'Git creates and pushes the release tag.'
    $gh = Get-RequiredApplication -Name 'gh' -Purpose 'The GitHub CLI publishes the GitHub Release.'
    $localTagNames = @(Invoke-ExternalCommand -FilePath $git -ArgumentList @('tag', '--list', $tagName))
    if ($localTagNames.Count -gt 0) {
        $localTagCommit = @(Invoke-ExternalCommand -FilePath $git -ArgumentList @(
                'rev-parse', '--verify', "$tagName^{commit}"
            )) -join ''
        if ($localTagCommit.Trim() -ne $ReleaseCommit) {
            throw "Local tag $tagName does not point to release commit $ReleaseCommit."
        }
    }

    $action = 'Pack the module and complete its tag, PowerShell Gallery, and GitHub Release publication'
    if (-not $PSCmdlet.ShouldProcess("PSWinUtil $Version at $ReleaseCommit", $action)) {
        return
    }

    if (-not $State.GalleryExists -and [string]::IsNullOrWhiteSpace($env:PSGALLERY_API_KEY)) {
        throw 'Set the PSGALLERY_API_KEY environment variable before publishing to PowerShell Gallery.'
    }

    Invoke-ReleasePack -ModuleDirectory $ModuleDirectory -ArtifactPath $ArtifactPath

    if (-not $State.TagExists) {
        if ($localTagNames.Count -eq 0) {
            Invoke-ExternalCommand -FilePath $git -ArgumentList @(
                'tag', '--annotate', $tagName, '--message', "PSWinUtil $Version", $ReleaseCommit
            ) | Out-Null
        }
        Invoke-ExternalCommand -FilePath $git -ArgumentList @('push', 'origin', "refs/tags/$tagName") | Out-Null
    }

    if (-not $State.GalleryExists) {
        Import-RequiredModule -Name 'Microsoft.PowerShell.PSResourceGet'
        Publish-PSResource `
            -Path $ModuleDirectory `
            -Repository 'PSGallery' `
            -ApiKey $env:PSGALLERY_API_KEY `
            -ErrorAction Stop | Out-Null

        Wait-GalleryPublication -Version $Version
    }

    $releaseArguments = @(
        'release', 'create', $tagName, $ArtifactPath, '--verify-tag', '--title', $Version, '--generate-notes'
    )
    $parsedVersion = ConvertTo-ReleaseVersion -Version $Version
    if (-not [string]::IsNullOrWhiteSpace($parsedVersion.Prerelease)) {
        $releaseArguments += '--prerelease'
    }
    Invoke-ExternalCommand -FilePath $gh -ArgumentList $releaseArguments | Out-Null

    [pscustomobject]@{
        Version = $Version
        TagName = $tagName
        ArtifactPath = $ArtifactPath
    }
}

function Wait-GalleryPublication {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$Version,

        [Parameter()]
        [ValidateRange(1, 120)]
        [int]$MaximumAttempt = 12,

        [Parameter()]
        [ValidateRange(0, 300)]
        [int]$RetryDelaySecond = 10
    )

    Import-RequiredModule -Name 'Microsoft.PowerShell.PSResourceGet'
    for ($attempt = 1; $attempt -le $MaximumAttempt; $attempt++) {
        if (Test-GalleryPublication -Version $Version) {
            return
        }

        if ($attempt -lt $MaximumAttempt) {
            Start-Sleep -Seconds $RetryDelaySecond
        }
    }

    throw "PowerShell Gallery did not expose PSWinUtil $Version within the expected time."
}

function Invoke-DevVerify {
    Import-RequiredModule -Name 'PSScriptAnalyzer'
    Import-RequiredModule -Name 'ModuleBuilder'
    Import-RequiredModule -Name 'Pester'
    Assert-DevSource
    Invoke-DevFormat -Check
    Invoke-DevAnalyze
    Invoke-DevBuild
    Assert-DevOutput
    Invoke-DevTest -SelectedTestType 'all' -SkipBuild
}

switch ($Command) {
    'format' {
        Assert-DevSource
        Import-RequiredModule -Name 'PSScriptAnalyzer'
        Invoke-DevFormat
    }
    'analyze' {
        Assert-DevSource
        Import-RequiredModule -Name 'PSScriptAnalyzer'
        Invoke-DevAnalyze
    }
    'lint' {
        Import-RequiredModule -Name 'PSScriptAnalyzer'
        Assert-DevSource
        Invoke-DevFormat -Check
        Invoke-DevAnalyze
    }
    'build' {
        Assert-DevSource
        Import-RequiredModule -Name 'ModuleBuilder'
        Invoke-DevBuild
    }
    'import' {
        Invoke-DevImport
    }
    'docs' {
        if (-not [string]::IsNullOrWhiteSpace($Argument) -and $Argument -ne 'check') {
            throw "The docs command accepts only 'check' as an argument."
        }

        Assert-DevSource
        Import-RequiredModule -Name 'ModuleBuilder'
        Invoke-DevBuild
        Update-CommandReference `
            -ManifestPath $outputManifestPath `
            -Path $commandReferencePath `
            -Check:($Argument -eq 'check')
    }
    'test' {
        $selectedTestType = 'all'
        if (-not [string]::IsNullOrWhiteSpace($Argument)) {
            $selectedTestType = $Argument
        }
        if ($selectedTestType -notin @('unit', 'integration', 'contract', 'all')) {
            throw "The test command accepts unit, integration, contract, or all: $selectedTestType"
        }

        Assert-DevSource
        Import-RequiredModule -Name 'ModuleBuilder'
        Import-RequiredModule -Name 'Pester'
        Invoke-DevTest -SelectedTestType $selectedTestType
    }
    'test-online-integration' {
        Assert-DevSource
        Import-RequiredModule -Name 'ModuleBuilder'
        Import-RequiredModule -Name 'Pester'
        Invoke-DevOnlineIntegrationTest
    }
    'verify' {
        Invoke-DevVerify
    }
    'ci' {
        Invoke-DevVerify
    }
    'bump' {
        if ([string]::IsNullOrWhiteSpace($Argument)) {
            throw 'The bump command requires a version. Example: .\dev.ps1 bump 1.2.3'
        }

        Invoke-Bump -Version $Argument
    }
    'release' {
        if ([string]::IsNullOrWhiteSpace($Argument)) {
            throw 'The release command requires the merged release commit.'
        }
        if ([string]::IsNullOrWhiteSpace($Branch)) {
            throw 'The release command requires the release branch with -Branch.'
        }

        Invoke-Release -ReleaseCommit $Argument -Branch $Branch
    }
}
