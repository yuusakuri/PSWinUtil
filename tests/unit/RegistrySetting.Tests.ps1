BeforeAll {
    . (Join-Path -Path $PSScriptRoot -ChildPath '../UnitTestBootstrap.ps1')

    InModuleScope -ModuleName PSWinUtil {
        $script:TestRegistrySettingData = @{
            Settings = @(
                @{
                    Name = 'Sample'
                    Configurations = @(
                        @{
                            Scope = 'User'
                            Properties = @(
                                @{
                                    Name = 'First'
                                    Path = 'Registry::HKEY_CURRENT_USER\Software\PSWinUtilTest\User'
                                    Type = 'DWord'
                                    Options = @(
                                        @{ Name = 'Enable'; Action = 'Set'; Value = 1 }
                                        @{ Name = 'Disable'; Action = 'Set'; Value = 0 }
                                    )
                                }
                                @{
                                    Name = 'Second'
                                    Path = 'Registry::HKEY_CURRENT_USER\Software\PSWinUtilTest\User'
                                    Type = 'DWord'
                                    Options = @(
                                        @{ Name = 'Enable'; Action = 'Set'; Value = 1 }
                                        @{ Name = 'Disable'; Action = 'Set'; Value = 0 }
                                    )
                                }
                            )
                        }
                        @{
                            Scope = 'Machine'
                            Properties = @(
                                @{
                                    Name = 'First'
                                    Path = 'Registry::HKEY_LOCAL_MACHINE\Software\PSWinUtilTest\Machine'
                                    Type = 'DWord'
                                    Options = @(
                                        @{ Name = 'Enable'; Action = 'Set'; Value = 1 }
                                        @{ Name = 'Disable'; Action = 'Set'; Value = 0 }
                                    )
                                }
                                @{
                                    Name = 'Second'
                                    Path = 'Registry::HKEY_LOCAL_MACHINE\Software\PSWinUtilTest\Machine'
                                    Type = 'DWord'
                                    Options = @(
                                        @{ Name = 'Enable'; Action = 'Set'; Value = 1 }
                                        @{ Name = 'Disable'; Action = 'Set'; Value = 0 }
                                    )
                                }
                            )
                        }
                    )
                }
                @{
                    Name = 'Removable'
                    Configurations = @(
                        @{
                            Scope = 'User'
                            Properties = @(
                                @{
                                    Name = 'RemovedValue'
                                    Path = 'Registry::HKEY_CURRENT_USER\Software\PSWinUtilTest\User'
                                    Type = 'DWord'
                                    Options = @(
                                        @{ Name = 'Default'; Action = 'Remove' }
                                        @{ Name = 'Disabled'; Action = 'Set'; Value = 1 }
                                    )
                                }
                            )
                        }
                    )
                }
            )
        }
    }
    $script:TestRegistrySettingData = InModuleScope -ModuleName PSWinUtil {
        $script:TestRegistrySettingData
    }
}



Describe 'Get-WURegistrySetting' {
    BeforeEach {
        $script:TestRegistryValues = @{}
        Mock -CommandName Import-WURegistrySetting -ModuleName PSWinUtil -MockWith {
            $script:TestRegistrySettingData
        }
        Mock -CommandName Get-WURegistryProperty -ModuleName PSWinUtil -MockWith {
            $key = $Path + '|' + $Name
            if ($script:TestRegistryValues.ContainsKey($key)) {
                [pscustomobject]@{
                    Path = $Path
                    Name = $Name
                    Type = 'DWord'
                    Value = $script:TestRegistryValues[$key]
                }
            }
        }
    }

    It 'uses the User configuration before the Machine configuration with Auto' {
        $path = 'Registry::HKEY_CURRENT_USER\Software\PSWinUtilTest\User'
        $script:TestRegistryValues[$path + '|First'] = 1
        $script:TestRegistryValues[$path + '|Second'] = 1

        $result = Get-WURegistrySetting -Name Sample

        $result.Scope | Should -Be 'User'
        $result.State | Should -Be 'Enable'
        $result.PSObject.TypeNames | Should -Contain 'PSWinUtil.RegistrySetting'
    }

    It 'uses the Machine configuration when Machine is selected' {
        $path = 'Registry::HKEY_LOCAL_MACHINE\Software\PSWinUtilTest\Machine'
        $script:TestRegistryValues[$path + '|First'] = 0
        $script:TestRegistryValues[$path + '|Second'] = 0

        $result = Get-WURegistrySetting -Name Sample -Scope Machine

        $result.Scope | Should -Be 'Machine'
        $result.State | Should -Be 'Disable'
    }

    It 'gets state independently from multiple scopes' {
        $userPath = 'Registry::HKEY_CURRENT_USER\Software\PSWinUtilTest\User'
        $machinePath = 'Registry::HKEY_LOCAL_MACHINE\Software\PSWinUtilTest\Machine'
        $script:TestRegistryValues[$userPath + '|First'] = 1
        $script:TestRegistryValues[$userPath + '|Second'] = 1
        $script:TestRegistryValues[$machinePath + '|First'] = 0
        $script:TestRegistryValues[$machinePath + '|Second'] = 0

        $result = @(Get-WURegistrySetting -Name Sample -Scope User, Machine)

        $result | Should -HaveCount 2
        ($result | Where-Object { $_.Scope -eq 'User' }).State | Should -Be 'Enable'
        ($result | Where-Object { $_.Scope -eq 'Machine' }).State | Should -Be 'Disable'
    }

    It 'rejects Auto combined with an explicit scope' {
        {
            Get-WURegistrySetting -Name Sample -Scope Auto, User
        } | Should -Throw '*cannot be combined*'
    }

    It 'returns a Remove option before NotConfigured' {
        $result = Get-WURegistrySetting -Name Removable

        $result.State | Should -Be 'Default'
    }

    It 'returns NotConfigured when all properties are missing and no option matches' {
        $result = Get-WURegistrySetting -Name Sample

        $result.State | Should -Be 'NotConfigured'
    }

    It 'returns Mixed when property values do not match one option' {
        $path = 'Registry::HKEY_CURRENT_USER\Software\PSWinUtilTest\User'
        $script:TestRegistryValues[$path + '|First'] = 1
        $script:TestRegistryValues[$path + '|Second'] = 0

        $result = Get-WURegistrySetting -Name Sample

        $result.State | Should -Be 'Mixed'
    }
}




