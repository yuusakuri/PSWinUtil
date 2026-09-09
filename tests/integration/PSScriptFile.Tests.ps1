BeforeAll {
    . (Join-Path -Path $PSScriptRoot -ChildPath '../UnitTestBootstrap.ps1')
}

Describe 'PowerShell script file behavior' {
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

    It 'accepts LiteralPath for a valid script file' {
        $scriptFile = Join-Path -Path $TestDrive -ChildPath 'assert[1].ps1'
        [System.IO.File]::WriteAllText($scriptFile, "Get-Item -Path .`n")

        { Assert-WUPSScript -LiteralPath $scriptFile } | Should -Not -Throw
    }
}
