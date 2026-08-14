[CmdletBinding()]
param(
    [Parameter(Position = 0)]
    [ValidateSet('format', 'analyze', 'build', 'test', 'ci')]
    [string]$Command,

    [Parameter(Position = 1)]
    [ValidateSet('unit', 'integration', 'contract', 'all')]
    [string]$TestType = 'all'
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
$formatterSettingsPath = Join-Path -Path $repositoryRoot -ChildPath 'PSScriptFormatterSettings.psd1'
$analyzerSettingsPath = Join-Path -Path $repositoryRoot -ChildPath 'PSScriptAnalyzerSettings.psd1'
$requirementsPath = Join-Path -Path $repositoryRoot -ChildPath 'build.requirements.psd1'

$writeUsage = {
    Write-Output -InputObject @'
Usage:
  .\run.ps1 format
  .\run.ps1 analyze
  .\run.ps1 build
  .\run.ps1 test unit
  .\run.ps1 test integration
  .\run.ps1 test contract
  .\run.ps1 test all
  .\run.ps1 ci
'@
}

if ([string]::IsNullOrWhiteSpace($Command)) {
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
    }
    catch {
        throw "Install $Name $requiredVersion before running this command. $($_.Exception.Message)"
    }
}

$getSourceFiles = {
    $rootFileNames = @(
        'run.ps1'
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

$invokeBuild = {
    if (Test-Path -LiteralPath $outputModuleDirectory) {
        Remove-Item -LiteralPath $outputModuleDirectory -Recurse -Force
    }

    Build-Module -SourcePath $buildConfigurationPath | Out-Null

    foreach ($expectedPath in @($outputManifestPath, $outputModulePath)) {
        if (-not (Test-Path -LiteralPath $expectedPath -PathType Leaf)) {
            throw "ModuleBuilder did not generate an expected file: $expectedPath"
        }
    }

    $generatedPowerShellFiles = @(
        Get-ChildItem -LiteralPath $outputModuleDirectory -File -Recurse |
            Where-Object { $_.Extension -in @('.ps1', '.psd1', '.psm1', '.ps1xml') }
    )
    foreach ($generatedPowerShellFile in $generatedPowerShellFiles) {
        $generatedPowerShellText = [System.IO.File]::ReadAllText($generatedPowerShellFile.FullName)
        [System.IO.File]::WriteAllText(
            $generatedPowerShellFile.FullName,
            $generatedPowerShellText,
            [System.Text.Encoding]::ASCII
        )
    }
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
        foreach ($currentTestType in $testTypes) {
            Join-Path -Path $repositoryRoot -ChildPath "tests/$currentTestType"
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
    'build' {
        & $assertSource
        & $importRequiredModule -Name 'ModuleBuilder'
        & $invokeBuild
    }
    'test' {
        & $assertSource
        & $importRequiredModule -Name 'ModuleBuilder'
        & $importRequiredModule -Name 'Pester'
        & $invokeTest -SelectedTestType $TestType
    }
    'ci' {
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
}
