BeforeAll {
    . (Join-Path -Path $PSScriptRoot -ChildPath '../UnitTestBootstrap.ps1')
}

Describe 'Test-WUEnvironmentVariableSetting' {
    It 'accepts a Hashtable with string keys and values' {
        InModuleScope -ModuleName PSWinUtil {
            Test-WUEnvironmentVariableSetting -Setting @{
                FIRST_NAME = 'first value'
                SECOND_NAME = 'second=value'
            }
        } | Should -BeTrue
    }

    It 'rejects a root that is not a Hashtable' {
        InModuleScope -ModuleName PSWinUtil {
            Test-WUEnvironmentVariableSetting -Setting 'not a Hashtable'
        } | Should -BeFalse
    }

    It 'rejects an invalid environment variable name' {
        InModuleScope -ModuleName PSWinUtil {
            Test-WUEnvironmentVariableSetting -Setting @{
                'INVALID=NAME' = 'value'
            }
        } | Should -BeFalse
    }

    It 'rejects a non-string value' {
        InModuleScope -ModuleName PSWinUtil {
            Test-WUEnvironmentVariableSetting -Setting @{
                INVALID_VALUE = 123
            }
        } | Should -BeFalse
    }
}

Describe 'Import-WUEnvironmentVariableSetting' {
    It 'returns validated settings from a PowerShell data file' {
        $environmentFile = Join-Path -Path $TestDrive -ChildPath 'environment.psd1'
        [System.IO.File]::WriteAllText(
            $environmentFile,
            "@{`n    FIRST_NAME = 'first value'`n    SECOND_NAME = 'second=value'`n}`n",
            [System.Text.UTF8Encoding]::new($false)
        )

        $settings = InModuleScope -ModuleName PSWinUtil -Parameters @{ DataPath = $environmentFile } {
            param($DataPath)
            @(Import-WUEnvironmentVariableSetting -Path $DataPath -Scope User)
        }

        $settings.Count | Should -Be 2
        $firstSetting = $settings | Where-Object { $_.Name -eq 'FIRST_NAME' }
        $firstSetting.Value | Should -Be 'first value'
        $firstSetting.Scope | Should -Be 'User'
    }

    It 'returns each setting for every selected scope' {
        $environmentFile = Join-Path -Path $TestDrive -ChildPath 'multiple-scopes.psd1'
        [System.IO.File]::WriteAllText(
            $environmentFile,
            "@{`n    NAME = 'value'`n}`n",
            [System.Text.UTF8Encoding]::new($false)
        )

        $settings = InModuleScope -ModuleName PSWinUtil -Parameters @{ DataPath = $environmentFile } {
            param($DataPath)
            @(
                Import-WUEnvironmentVariableSetting `
                    -Path $DataPath `
                    -Scope Process, User
            )
        }

        $settings | Should -HaveCount 2
        $settings.Scope | Should -Contain 'Process'
        $settings.Scope | Should -Contain 'User'
    }

    It 'imports a LiteralPath without wildcard interpretation' {
        $environmentFile = Join-Path -Path $TestDrive -ChildPath 'environment[1].psd1'
        [System.IO.File]::WriteAllText(
            $environmentFile,
            "@{`n    NAME = 'literal value'`n}`n",
            [System.Text.UTF8Encoding]::new($false)
        )

        $settings = InModuleScope -ModuleName PSWinUtil -Parameters @{ DataPath = $environmentFile } {
            param($DataPath)
            @(Import-WUEnvironmentVariableSetting -LiteralPath $DataPath -Scope User)
        }

        $settings | Should -HaveCount 1
        $settings[0].Value | Should -Be 'literal value'
    }

    It 'delegates data validation to the validator' {
        $environmentFile = Join-Path -Path $TestDrive -ChildPath 'environment.psd1'
        [System.IO.File]::WriteAllText(
            $environmentFile,
            "@{`n    NAME = 'value'`n}`n",
            [System.Text.UTF8Encoding]::new($false)
        )
        Mock -CommandName Test-WUEnvironmentVariableSetting -ModuleName PSWinUtil -MockWith { $true }

        InModuleScope -ModuleName PSWinUtil -Parameters @{ DataPath = $environmentFile } {
            param($DataPath)
            Import-WUEnvironmentVariableSetting -Path $DataPath -Scope Process
        }

        Should -Invoke -CommandName Test-WUEnvironmentVariableSetting -ModuleName PSWinUtil -Times 1 -Exactly
    }

    It 'rejects invalid setting data' {
        $environmentFile = Join-Path -Path $TestDrive -ChildPath 'invalid.psd1'
        [System.IO.File]::WriteAllText(
            $environmentFile,
            "@{`n    NAME = 123`n}`n",
            [System.Text.UTF8Encoding]::new($false)
        )

        {
            InModuleScope -ModuleName PSWinUtil -Parameters @{ DataPath = $environmentFile } {
                param($DataPath)
                Import-WUEnvironmentVariableSetting -Path $DataPath -Scope Process
            }
        } | Should -Throw '*must contain valid environment variable settings*'
    }

    It 'rejects a file that does not use the psd1 extension' {
        $environmentFile = Join-Path -Path $TestDrive -ChildPath 'environment.txt'
        [System.IO.File]::WriteAllText(
            $environmentFile,
            "@{}`n",
            [System.Text.UTF8Encoding]::new($false)
        )

        {
            InModuleScope -ModuleName PSWinUtil -Parameters @{ DataPath = $environmentFile } {
                param($DataPath)
                Import-WUEnvironmentVariableSetting -Path $DataPath -Scope Process
            }
        } | Should -Throw '*.psd1 extension*'
    }

    It 'rejects a missing file' {
        $environmentFile = Join-Path -Path $TestDrive -ChildPath 'missing.psd1'

        {
            InModuleScope -ModuleName PSWinUtil -Parameters @{ DataPath = $environmentFile } {
                param($DataPath)
                Import-WUEnvironmentVariableSetting -Path $DataPath -Scope Process
            }
        } | Should -Throw
    }
}
