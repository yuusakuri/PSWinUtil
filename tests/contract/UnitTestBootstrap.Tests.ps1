BeforeAll {
    $repositoryRoot = Split-Path -Path (Split-Path -Path $PSScriptRoot -Parent) -Parent
    $script:DevelopmentScriptPath = Join-Path -Path $repositoryRoot -ChildPath 'dev.ps1'
    $script:UnitTestPath = Join-Path -Path $repositoryRoot -ChildPath 'tests/unit'
}

Describe 'Unit test bootstrap' {
    It 'imports the built module once before running the unit suite' {
        $developmentScriptText = [System.IO.File]::ReadAllText($script:DevelopmentScriptPath)

        $developmentScriptText | Should -Match 'if \(''unit'' -in \$testTypes\)'
        $developmentScriptText |
            Should -Match 'Import-Module -Name \$outputManifestPath -Force -ErrorAction Stop'
    }

    It 'does not repeat repository and manifest imports in unit test files' {
        $unitTestFiles = Get-ChildItem -LiteralPath $script:UnitTestPath -Filter '*.Tests.ps1' -File

        foreach ($unitTestFile in $unitTestFiles) {
            $unitTestText = [System.IO.File]::ReadAllText($unitTestFile.FullName)
            $unitTestText | Should -Not -Match '\$repositoryRoot = Split-Path'
            $unitTestText | Should -Not -Match 'output/PSWinUtil/PSWinUtil\.psd1'
            $unitTestText | Should -Not -Match 'Import-Module -Name \$manifestPath'
        }
    }
}
