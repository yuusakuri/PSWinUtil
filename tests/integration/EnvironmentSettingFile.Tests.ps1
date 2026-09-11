BeforeAll {
    . (Join-Path -Path $PSScriptRoot -ChildPath '../UnitTestBootstrap.ps1')
}

Describe 'Environment setting files through the public command' {
    BeforeEach {
        $script:SettingName = 'PSWINUTIL_FILE_' + [guid]::NewGuid().ToString('N')
        $script:SettingFile = Join-Path $TestDrive 'settings[1].psd1'
    }

    AfterEach {
        [Environment]::SetEnvironmentVariable($script:SettingName, $null, 'Process')
        [Environment]::SetEnvironmentVariable($script:SettingName, $null, 'User')
    }

    It 'loads a literal data file into each selected scope' {
        [IO.File]::WriteAllText($script:SettingFile, "@{ $script:SettingName = 'first=value' }")
        Set-WUEnvironmentVariable -LiteralPath $script:SettingFile -Scope Process, User
        [Environment]::GetEnvironmentVariable($script:SettingName, 'Process') | Should -Be 'first=value'
        [Environment]::GetEnvironmentVariable($script:SettingName, 'User') | Should -Be 'first=value'
    }

    It 'loads wildcard paths and previews without applying settings' {
        [IO.File]::WriteAllText($script:SettingFile, "@{ $script:SettingName = 'value' }")
        Set-WUEnvironmentVariable -Path (Join-Path $TestDrive '*.psd1') -Scope Process -WhatIf
        [Environment]::GetEnvironmentVariable($script:SettingName, 'Process') | Should -BeNullOrEmpty
        Set-WUEnvironmentVariable -Path (Join-Path $TestDrive '*.psd1') -Scope Process
        [Environment]::GetEnvironmentVariable($script:SettingName, 'Process') | Should -Be 'value'
    }

    It 'rejects invalid data <Data> without applying any values' -TestCases @(
        @{ Data = "'not a hashtable'" }
        @{ Data = "@{ 'INVALID=NAME' = 'value' }" }
        @{ Data = '@{ INVALID_VALUE = 123 }' }
    ) {
        param($Data)
        [IO.File]::WriteAllText($script:SettingFile, $Data)
        { Set-WUEnvironmentVariable -LiteralPath $script:SettingFile -Scope Process } | Should -Throw
        [Environment]::GetEnvironmentVariable($script:SettingName, 'Process') | Should -BeNullOrEmpty
    }

    It 'rejects a missing file' {
        { Set-WUEnvironmentVariable -LiteralPath $script:SettingFile -Scope Process } | Should -Throw
    }

    It 'rejects a file with an unsupported extension' {
        $path = Join-Path $TestDrive 'settings.txt'
        [IO.File]::WriteAllText($path, '@{}')
        { Set-WUEnvironmentVariable -LiteralPath $path -Scope Process } | Should -Throw
    }
}
