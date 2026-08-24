$windowsPowerShellAvailable = $null -ne (
    Get-Command -Name 'powershell.exe' -CommandType Application -ErrorAction SilentlyContinue
)

BeforeAll {
    $repositoryRoot = Split-Path -Path (Split-Path -Path $PSScriptRoot -Parent) -Parent
    $manifestPath = Join-Path -Path $repositoryRoot -ChildPath 'output/PSWinUtil/PSWinUtil.psd1'
    Import-Module -Name $manifestPath -Force -ErrorAction Stop
}

Describe 'File system utility integration' {
    BeforeEach {
        $script:DirectoryPath = Join-Path -Path $TestDrive -ChildPath 'directory'
        $null = New-Item -Path $script:DirectoryPath -ItemType Directory
        $script:FilePath = Join-Path -Path $script:DirectoryPath -ChildPath 'file.txt'
        [System.IO.File]::WriteAllText($script:FilePath, 'value')
    }

    It 'converts and tests a temporary file and directory' {
        ConvertTo-WUFullPath -Path $script:FilePath | Should -Be $script:FilePath
        Test-WUPathProperty -Path $script:FilePath -Leaf -Readable -Writable | Should -BeTrue
        Test-WUPathProperty -Path $script:DirectoryPath -Container -Readable -Writable | Should -BeTrue
        { Assert-WUPathProperty -Path $script:FilePath -Leaf -Readable } | Should -Not -Throw
    }
}

Describe 'PowerShell parser integration' {
    It 'parses valid and invalid temporary scripts' {
        $validScript = Join-Path -Path $TestDrive -ChildPath 'valid.ps1'
        $invalidScript = Join-Path -Path $TestDrive -ChildPath 'invalid.ps1'
        [System.IO.File]::WriteAllText($validScript, "Get-Item -Path .`n")
        [System.IO.File]::WriteAllText($invalidScript, "if (`n")

        Test-WUPSScript -Path $validScript | Should -BeTrue
        Test-WUPSScript -Path $invalidScript | Should -BeFalse
        { Assert-WUPSScript -Path $invalidScript } | Should -Throw
    }
}

Describe 'URI and random string integration' {
    It 'uses System.Uri without network access' {
        $joinedUri = Join-WUUri -BaseUri 'https://example.test/api/' -RelativeUri 'items'
        $convertedUri = Convert-WUUri -Uri "$($joinedUri.AbsoluteUri)?q=value#top" -WithoutQuery -WithoutFragment

        $convertedUri.AbsoluteUri | Should -Be 'https://example.test/api/items'
    }

    It 'creates random strings with the required format' {
        1..5 | ForEach-Object {
            $value = New-WURandomString -Length 64
            $value.Length | Should -Be 64
            $value | Should -Match '^[A-Za-z0-9]+$'
        }
    }
}

Describe 'Administrator script validation integration' -Skip:(-not $windowsPowerShellAvailable) {
    It 'validates a script without opening the UAC interface' {
        $scriptFile = Join-Path -Path $TestDrive -ChildPath 'admin.ps1'
        [System.IO.File]::WriteAllText($scriptFile, "Get-Item -Path .`n")

        { Start-WUPSScriptAsAdmin -Path $scriptFile -ArgumentList 'test' -WhatIf } | Should -Not -Throw
    }
}
