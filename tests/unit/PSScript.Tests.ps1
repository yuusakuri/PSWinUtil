BeforeAll {
    $repositoryRoot = Split-Path -Path (Split-Path -Path $PSScriptRoot -Parent) -Parent
    $manifestPath = Join-Path -Path $repositoryRoot -ChildPath 'output/PSWinUtil/PSWinUtil.psd1'
    Import-Module -Name $manifestPath -Force -ErrorAction Stop
}

Describe 'Test-WUPSScript' {
    It 'returns true for valid script text' {
        Test-WUPSScript -Script 'Get-Item -Path .' | Should -BeTrue
    }

    It 'returns false for invalid script text' {
        Test-WUPSScript -Script 'if (' | Should -BeFalse
    }

    It 'returns parser details when requested' {
        $result = Test-WUPSScript -Script 'if (' -Detailed

        $result.IsValid | Should -BeFalse
        $result.Errors.Count | Should -BeGreaterThan 0
        $result.Errors[0].Extent.StartLineNumber | Should -BeGreaterOrEqual 1
    }

    It 'parses a script file' {
        $scriptFile = Join-Path -Path $TestDrive -ChildPath 'valid.ps1'
        [System.IO.File]::WriteAllText($scriptFile, "Get-Item -Path .`n")

        Test-WUPSScript -Path $scriptFile | Should -BeTrue
    }

    It 'expands wildcard Path values' {
        $scriptDirectory = Join-Path -Path $TestDrive -ChildPath 'wildcard-scripts'
        $null = New-Item -Path $scriptDirectory -ItemType Directory -Force
        $firstScript = Join-Path -Path $scriptDirectory -ChildPath 'first.ps1'
        $secondScript = Join-Path -Path $scriptDirectory -ChildPath 'second.ps1'
        [System.IO.File]::WriteAllText($firstScript, "Get-Item -Path .`n")
        [System.IO.File]::WriteAllText($secondScript, "if (`$true) { 'valid' }`n")

        $result = @(
            Test-WUPSScript -Path (Join-Path -Path $scriptDirectory -ChildPath '*.ps1')
        )

        $result | Should -HaveCount 2
        $result | ForEach-Object { $_ | Should -BeTrue }
    }

    It 'parses LiteralPath without wildcard interpretation' {
        $scriptFile = Join-Path -Path $TestDrive -ChildPath 'literal[1].ps1'
        [System.IO.File]::WriteAllText($scriptFile, "Get-Item -Path .`n")

        Test-WUPSScript -LiteralPath $scriptFile | Should -BeTrue
    }
}

Describe 'Assert-WUPSScript' {
    It 'produces no output for valid syntax' {
        $result = Assert-WUPSScript -Script 'Get-Item -Path .'

        $result | Should -BeNullOrEmpty
    }

    It 'reports parser errors for invalid syntax' {
        { Assert-WUPSScript -Script 'if (' } | Should -Throw '*parser errors*'
    }

    It 'accepts LiteralPath for a valid script file' {
        $scriptFile = Join-Path -Path $TestDrive -ChildPath 'assert[1].ps1'
        [System.IO.File]::WriteAllText($scriptFile, "Get-Item -Path .`n")

        { Assert-WUPSScript -LiteralPath $scriptFile } | Should -Not -Throw
    }
}
