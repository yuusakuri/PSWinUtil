BeforeAll {
    . (Join-Path -Path $PSScriptRoot -ChildPath '../UnitTestBootstrap.ps1')

    $script:RegistryPath = 'Registry::HKEY_CURRENT_USER\Software\PSWinUtilTest'
}

Describe 'Compare-WURegistryValue' {
    It 'compares scalar and array values without text conversion' {
        InModuleScope -ModuleName PSWinUtil {
            Compare-WURegistryValue -ReferenceValue 1 -DifferenceValue 1 |
                Should -BeTrue
            Compare-WURegistryValue `
                -ReferenceValue @('first', 'second') `
                -DifferenceValue @('first', 'second') |
                Should -BeTrue
            Compare-WURegistryValue `
                -ReferenceValue @('first', 'second') `
                -DifferenceValue @('second', 'first') |
                Should -BeFalse
        }
    }
}

Describe 'Set-WURegistryProperty unit behavior' {
    BeforeEach {
        Mock -CommandName Get-WURegistryProperty -ModuleName PSWinUtil
        Mock -CommandName Test-Path -ModuleName PSWinUtil -MockWith { $false }
        Mock -CommandName New-Item -ModuleName PSWinUtil
        Mock -CommandName New-ItemProperty -ModuleName PSWinUtil
        Mock -CommandName Get-Item -ModuleName PSWinUtil -MockWith {
            [pscustomobject]@{
                SetValue = { }
            }
        }
    }

    It 'creates a missing key and property' {
        Set-WURegistryProperty `
            -Path $script:RegistryPath `
            -Name 'Enabled' `
            -Value 1 `
            -Type DWord

        Should -Invoke -CommandName New-Item -ModuleName PSWinUtil -Times 1 -Exactly
        Should -Invoke -CommandName New-ItemProperty -ModuleName PSWinUtil -Times 1 -Exactly -ParameterFilter {
            $Name -eq 'Enabled' -and $Value -eq 1 -and $PropertyType -eq 'DWord'
        }
    }

    It 'preserves the Binary value type before writing' {
        Set-WURegistryProperty `
            -Path $script:RegistryPath `
            -Name 'Bytes' `
            -Value @(1, 2) `
            -Type Binary

        Should -Invoke -CommandName New-ItemProperty -ModuleName PSWinUtil -Times 1 -Exactly -ParameterFilter {
            $Value -is [byte[]]
        }
    }

    It 'does not write an identical value and type' {
        Mock -CommandName Get-WURegistryProperty -ModuleName PSWinUtil -MockWith {
            [pscustomobject]@{
                Path = $Path
                Name = $Name
                Value = 1
                Type = 'DWord'
            }
        }

        Set-WURegistryProperty `
            -Path $script:RegistryPath `
            -Name 'Enabled' `
            -Value 1 `
            -Type DWord

        Should -Invoke -CommandName New-Item -ModuleName PSWinUtil -Times 0 -Exactly
        Should -Invoke -CommandName New-ItemProperty -ModuleName PSWinUtil -Times 0 -Exactly
    }

    It 'does not create a key or property with WhatIf' {
        Set-WURegistryProperty `
            -Path $script:RegistryPath `
            -Name 'Enabled' `
            -Value 1 `
            -Type DWord `
            -WhatIf

        Should -Invoke -CommandName New-Item -ModuleName PSWinUtil -Times 0 -Exactly
        Should -Invoke -CommandName New-ItemProperty -ModuleName PSWinUtil -Times 0 -Exactly
    }

    It 'sets the default value through the registry key API' {
        $script:DefaultValueArguments = $null
        Mock -CommandName Open-WURegistryKeyForWrite -ModuleName PSWinUtil -MockWith {
            $registryKey = [pscustomobject]@{}
            $registryKey | Add-Member -MemberType ScriptMethod -Name SetValue -Value {
                $script:DefaultValueArguments = @($args)
            }
            $registryKey | Add-Member -MemberType ScriptMethod -Name Dispose -Value {}
            $registryKey
        }

        Set-WURegistryProperty `
            -Path $script:RegistryPath `
            -Name '' `
            -Value '' `
            -Type String

        $script:DefaultValueArguments[0] | Should -Be ''
        $script:DefaultValueArguments[1] | Should -Be ''
        $script:DefaultValueArguments[2] | Should -Be ([Microsoft.Win32.RegistryValueKind]::String)
        Should -Invoke -CommandName New-ItemProperty -ModuleName PSWinUtil -Times 0 -Exactly
    }
}

Describe 'Remove-WURegistryProperty unit behavior' {
    BeforeEach {
        Mock -CommandName Get-WURegistryProperty -ModuleName PSWinUtil
        Mock -CommandName Remove-ItemProperty -ModuleName PSWinUtil
        Mock -CommandName Get-Item -ModuleName PSWinUtil
    }

    It 'does not remove a missing property' {
        Remove-WURegistryProperty `
            -Path $script:RegistryPath `
            -Name 'Missing'

        Should -Invoke -CommandName Remove-ItemProperty -ModuleName PSWinUtil -Times 0 -Exactly
    }

    It 'removes an existing property' {
        Mock -CommandName Get-WURegistryProperty -ModuleName PSWinUtil -MockWith {
            [pscustomobject]@{
                Path = $Path
                Name = $Name
                Value = 1
                Type = 'DWord'
            }
        }

        Remove-WURegistryProperty `
            -Path $script:RegistryPath `
            -Name 'Enabled'

        Should -Invoke -CommandName Remove-ItemProperty -ModuleName PSWinUtil -Times 1 -Exactly
    }

    It 'does not remove an existing property with WhatIf' {
        Mock -CommandName Get-WURegistryProperty -ModuleName PSWinUtil -MockWith {
            [pscustomobject]@{
                Path = $Path
                Name = $Name
                Value = 1
                Type = 'DWord'
            }
        }

        Remove-WURegistryProperty `
            -Path $script:RegistryPath `
            -Name 'Enabled' `
            -WhatIf

        Should -Invoke -CommandName Remove-ItemProperty -ModuleName PSWinUtil -Times 0 -Exactly
    }

    It 'removes the default value through the registry key API' {
        $script:DeletedDefaultValueArguments = $null
        Mock -CommandName Get-WURegistryProperty -ModuleName PSWinUtil -MockWith {
            [pscustomobject]@{
                Path = $Path
                Name = $Name
                Value = ''
                Type = 'String'
            }
        }
        Mock -CommandName Open-WURegistryKeyForWrite -ModuleName PSWinUtil -MockWith {
            $registryKey = [pscustomobject]@{}
            $registryKey | Add-Member -MemberType ScriptMethod -Name DeleteValue -Value {
                $script:DeletedDefaultValueArguments = @($args)
            }
            $registryKey | Add-Member -MemberType ScriptMethod -Name Dispose -Value {}
            $registryKey
        }

        Remove-WURegistryProperty `
            -Path $script:RegistryPath `
            -Name ''

        $script:DeletedDefaultValueArguments[0] | Should -Be ''
        $script:DeletedDefaultValueArguments[1] | Should -BeFalse
        Should -Invoke -CommandName Remove-ItemProperty -ModuleName PSWinUtil -Times 0 -Exactly
    }
}
