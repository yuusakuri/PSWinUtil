BeforeAll {
    $repositoryRoot = Split-Path -Path (Split-Path -Path $PSScriptRoot -Parent) -Parent
    $manifestPath = Join-Path -Path $repositoryRoot -ChildPath 'output/PSWinUtil/PSWinUtil.psd1'
    Import-Module -Name $manifestPath -Force -ErrorAction Stop

    InModuleScope -ModuleName PSWinUtil {
        $script:TestRegistrySettingData = @{
            Sample = @{
                First = @(
                    @{
                        Path = 'Registry::HKEY_CURRENT_USER\Software\PSWinUtilTest\User'
                        Name = 'First'
                        Type = 'DWord'
                        Options = @{
                            Enable = @{ Action = 'Set'; Value = 1 }
                            Disable = @{ Action = 'Set'; Value = 0 }
                        }
                    }
                    @{
                        Path = 'Registry::HKEY_LOCAL_MACHINE\Software\PSWinUtilTest\Machine'
                        Name = 'First'
                        Type = 'DWord'
                        Options = @{
                            Enable = @{ Action = 'Set'; Value = 1 }
                            Disable = @{ Action = 'Set'; Value = 0 }
                        }
                    }
                )
                Second = @(
                    @{
                        Path = 'Registry::HKEY_CURRENT_USER\Software\PSWinUtilTest\User'
                        Name = 'Second'
                        Type = 'DWord'
                        Options = @{
                            Enable = @{ Action = 'Set'; Value = 1 }
                            Disable = @{ Action = 'Set'; Value = 0 }
                        }
                    }
                    @{
                        Path = 'Registry::HKEY_LOCAL_MACHINE\Software\PSWinUtilTest\Machine'
                        Name = 'Second'
                        Type = 'DWord'
                        Options = @{
                            Enable = @{ Action = 'Set'; Value = 1 }
                            Disable = @{ Action = 'Set'; Value = 0 }
                        }
                    }
                )
            }
            Removable = @{
                RemovedValue = @(
                    @{
                        Path = 'Registry::HKEY_CURRENT_USER\Software\PSWinUtilTest\User'
                        Name = 'RemovedValue'
                        Type = 'DWord'
                        Options = @{
                            Default = @{ Action = 'Remove' }
                            Disabled = @{ Action = 'Set'; Value = 1 }
                        }
                    }
                )
            }
        }
    }
    $script:TestRegistrySettingData = InModuleScope -ModuleName PSWinUtil {
        $script:TestRegistrySettingData
    }
}

Describe 'Registry setting schema' {
    It 'accepts complete setting data' {
        InModuleScope -ModuleName PSWinUtil {
            Test-WURegistrySetting -Setting $script:TestRegistrySettingData
        } | Should -BeTrue
    }

    It 'rejects an unsupported registry hive' {
        InModuleScope -ModuleName PSWinUtil {
            $invalidData = @{
                Invalid = @{
                    Value = @(
                        @{
                            Path = 'Registry::HKEY_CLASSES_ROOT\Invalid'
                            Name = 'Value'
                            Type = 'DWord'
                            Options = @{
                                Enable = @{ Action = 'Set'; Value = 1 }
                            }
                        }
                    )
                }
            }

            Test-WURegistrySetting -Setting $invalidData
        } | Should -BeFalse
    }

    It 'rejects property candidates with different options' {
        InModuleScope -ModuleName PSWinUtil {
            $invalidData = @{
                Invalid = @{
                    First = @(
                        @{
                            Path = 'Registry::HKEY_CURRENT_USER\Software\Invalid'
                            Name = 'First'
                            Type = 'DWord'
                            Options = @{
                                Enable = @{ Action = 'Set'; Value = 1 }
                            }
                        }
                    )
                    Second = @(
                        @{
                            Path = 'Registry::HKEY_CURRENT_USER\Software\Invalid'
                            Name = 'Second'
                            Type = 'DWord'
                            Options = @{
                                Disable = @{ Action = 'Set'; Value = 0 }
                            }
                        }
                    )
                }
            }

            Test-WURegistrySetting -Setting $invalidData
        } | Should -BeFalse
    }

    It 'rejects a Set action with a value that does not match its type' {
        InModuleScope -ModuleName PSWinUtil {
            $invalidData = @{
                Invalid = @{
                    Value = @(
                        @{
                            Path = 'Registry::HKEY_CURRENT_USER\Software\Invalid'
                            Name = 'Value'
                            Type = 'DWord'
                            Options = @{
                                Enable = @{ Action = 'Set'; Value = 'one' }
                            }
                        }
                    )
                }
            }

            Test-WURegistrySetting -Setting $invalidData
        } | Should -BeFalse
    }

    It 'imports and validates the distributed setting data' {
        InModuleScope -ModuleName PSWinUtil {
            $settings = Import-WURegistrySetting

            $settings.ContainsKey('DarkMode') | Should -BeTrue
            $settings.ContainsKey('WindowsUpdateNotificationLevel') | Should -BeTrue
            $settings.ContainsKey('DeviceSetupSuggestions') | Should -BeTrue
            $settings.ContainsKey('TaskbarAlignment') | Should -BeTrue
            $settings.ContainsKey('TaskbarSearchMode') | Should -BeTrue
            $settings.ContainsKey('JapaneseImeHalfWidthInput') | Should -BeTrue
        }
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

    It 'uses User candidates before Machine candidates with Auto' {
        $path = 'Registry::HKEY_CURRENT_USER\Software\PSWinUtilTest\User'
        $script:TestRegistryValues[$path + '|First'] = 1
        $script:TestRegistryValues[$path + '|Second'] = 1

        $result = Get-WURegistrySetting -Name Sample

        $result.Scope | Should -Be 'User'
        $result.State | Should -Be 'Enable'
        $result.PSObject.TypeNames | Should -Contain 'PSWinUtil.RegistrySetting'
    }

    It 'uses Machine candidates when Machine is selected' {
        $path = 'Registry::HKEY_LOCAL_MACHINE\Software\PSWinUtilTest\Machine'
        $script:TestRegistryValues[$path + '|First'] = 0
        $script:TestRegistryValues[$path + '|Second'] = 0

        $result = Get-WURegistrySetting -Name Sample -Scope Machine

        $result.Scope | Should -Be 'Machine'
        $result.State | Should -Be 'Disable'
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

Describe 'Set-WURegistrySetting' {
    BeforeEach {
        Mock -CommandName Import-WURegistrySetting -ModuleName PSWinUtil -MockWith {
            $script:TestRegistrySettingData
        }
        Mock -CommandName Get-WURegistrySetting -ModuleName PSWinUtil -MockWith {
            [pscustomobject]@{
                Name = $Name
                Scope = $Scope
                State = 'Mixed'
            }
        }
        Mock -CommandName Set-WURegistryProperty -ModuleName PSWinUtil
        Mock -CommandName Remove-WURegistryProperty -ModuleName PSWinUtil
    }

    It 'delegates Set actions to Set-WURegistryProperty' {
        InModuleScope -ModuleName PSWinUtil {
            Set-WURegistrySetting -Name Sample -Option Enable -Scope User
        }

        Should -Invoke -CommandName Set-WURegistryProperty -ModuleName PSWinUtil -Times 2 -Exactly -ParameterFilter {
            $Type -eq 'DWord' -and $Value -eq 1
        }
        Should -Invoke -CommandName Remove-WURegistryProperty -ModuleName PSWinUtil -Times 0 -Exactly
    }

    It 'delegates Remove actions to Remove-WURegistryProperty' {
        InModuleScope -ModuleName PSWinUtil {
            Set-WURegistrySetting -Name Removable -Option Default -Scope User
        }

        Should -Invoke -CommandName Remove-WURegistryProperty -ModuleName PSWinUtil -Times 1 -Exactly
        Should -Invoke -CommandName Set-WURegistryProperty -ModuleName PSWinUtil -Times 0 -Exactly
    }

    It 'does not write when the selected option already matches' {
        Mock -CommandName Get-WURegistrySetting -ModuleName PSWinUtil -MockWith {
            [pscustomobject]@{
                Name = $Name
                Scope = $Scope
                State = 'Enable'
            }
        }

        InModuleScope -ModuleName PSWinUtil {
            Set-WURegistrySetting -Name Sample -Option Enable -Scope User
        }

        Should -Invoke -CommandName Set-WURegistryProperty -ModuleName PSWinUtil -Times 0 -Exactly
        Should -Invoke -CommandName Remove-WURegistryProperty -ModuleName PSWinUtil -Times 0 -Exactly
    }

    It 'forwards WhatIf to registry property commands' {
        InModuleScope -ModuleName PSWinUtil {
            Set-WURegistrySetting `
                -Name Sample `
                -Option Enable `
                -Scope User `
                -WhatIf
        }

        Should -Invoke -CommandName Set-WURegistryProperty -ModuleName PSWinUtil -Times 2 -Exactly -ParameterFilter {
            $WhatIf -eq $true
        }
    }
}

Describe 'Setting-specific registry commands' {
    BeforeAll {
        $script:SettingCommands = @{
            'Enable-WUAppLaunchTracking' = @('AppLaunchTracking', 'Enable')
            'Disable-WUAppLaunchTracking' = @('AppLaunchTracking', 'Disable')
            'Enable-WUAppSuggestions' = @('AppSuggestions', 'Enable')
            'Disable-WUAppSuggestions' = @('AppSuggestions', 'Disable')
            'Enable-WUDarkMode' = @('DarkMode', 'Enable')
            'Disable-WUDarkMode' = @('DarkMode', 'Disable')
            'Enable-WUEdgeFirstRunExperience' = @('EdgeFirstRunExperience', 'Enable')
            'Disable-WUEdgeFirstRunExperience' = @('EdgeFirstRunExperience', 'Disable')
            'Enable-WUFileHistory' = @('FileHistory', 'Enable')
            'Disable-WUFileHistory' = @('FileHistory', 'Disable')
            'Enable-WULockScreen' = @('LockScreen', 'Enable')
            'Disable-WULockScreen' = @('LockScreen', 'Disable')
            'Enable-WULockWorkstation' = @('LockWorkstation', 'Enable')
            'Disable-WULockWorkstation' = @('LockWorkstation', 'Disable')
            'Enable-WULongPaths' = @('LongPaths', 'Enable')
            'Disable-WULongPaths' = @('LongPaths', 'Disable')
            'Enable-WUWidgets' = @('Widgets', 'Enable')
            'Disable-WUWidgets' = @('Widgets', 'Disable')
            'Enable-WURequireSignInOnWakeup' = @('RequireSignInOnWakeup', 'Enable')
            'Disable-WURequireSignInOnWakeup' = @('RequireSignInOnWakeup', 'Disable')
            'Enable-WUSaveZoneInformation' = @('SaveZoneInformation', 'Enable')
            'Disable-WUSaveZoneInformation' = @('SaveZoneInformation', 'Disable')
            'Enable-WUSmartScreenInShell' = @('SmartScreenInShell', 'Enable')
            'Disable-WUSmartScreenInShell' = @('SmartScreenInShell', 'Disable')
            'Enable-WUUac' = @('Uac', 'Enable')
            'Disable-WUUac' = @('Uac', 'Disable')
            'Enable-WUWebsiteAccessToLanguageList' = @('WebsiteAccessToLanguageList', 'Enable')
            'Disable-WUWebsiteAccessToLanguageList' = @('WebsiteAccessToLanguageList', 'Disable')
            'Enable-WUWindowsHelloForBusiness' = @('WindowsHelloForBusiness', 'Enable')
            'Disable-WUWindowsHelloForBusiness' = @('WindowsHelloForBusiness', 'Disable')
            'Enable-WUWindowsMediaPlayerFirstUseDialogBoxes' = @('WindowsMediaPlayerFirstUseDialogBoxes', 'Enable')
            'Disable-WUWindowsMediaPlayerFirstUseDialogBoxes' = @('WindowsMediaPlayerFirstUseDialogBoxes', 'Disable')
            'Enable-WUWindowsSecurityAllNotifications' = @('WindowsSecurityAllNotifications', 'Enable')
            'Disable-WUWindowsSecurityAllNotifications' = @('WindowsSecurityAllNotifications', 'Disable')
            'Enable-WUWindowsSecurityNonCriticalNotifications' = @('WindowsSecurityNonCriticalNotifications', 'Enable')
            'Disable-WUWindowsSecurityNonCriticalNotifications' = @('WindowsSecurityNonCriticalNotifications', 'Disable')
        }
    }

    It 'delegates every Enable and Disable command without registry details' {
        Mock -CommandName Set-WURegistrySetting -ModuleName PSWinUtil

        foreach ($commandName in $script:SettingCommands.Keys) {
            $expected = $script:SettingCommands[$commandName]
            & $commandName

            Should -Invoke -CommandName Set-WURegistrySetting -ModuleName PSWinUtil -Times 1 -Exactly -ParameterFilter {
                $Name -eq $expected[0] -and $Option -eq $expected[1]
            }
            (Get-Command -Name $commandName -Module PSWinUtil).ScriptBlock.ToString() |
                Should -Not -Match 'Registry::|HKEY_|Set-WURegistryProperty|Remove-WURegistryProperty'
        }
    }

    It 'delegates advertising ID modes' {
        Mock -CommandName Set-WURegistrySetting -ModuleName PSWinUtil

        Set-WUAdvertisingIdMode -Mode Disabled

        Should -Invoke -CommandName Set-WURegistrySetting -ModuleName PSWinUtil -Times 1 -Exactly -ParameterFilter {
            $Name -eq 'AdvertisingId' -and $Option -eq 'Disabled'
        }
    }

    It 'forwards WhatIf from a setting-specific command' {
        Mock -CommandName Set-WURegistrySetting -ModuleName PSWinUtil

        Enable-WUDarkMode -WhatIf

        Should -Invoke -CommandName Set-WURegistrySetting -ModuleName PSWinUtil -Times 1 -Exactly -ParameterFilter {
            $WhatIf -eq $true
        }
    }

    It 'delegates Windows Update notification levels' {
        Mock -CommandName Set-WURegistrySetting -ModuleName PSWinUtil

        Set-WUWindowsUpdateNotificationLevel -Level None

        Should -Invoke -CommandName Set-WURegistrySetting -ModuleName PSWinUtil -Times 1 -Exactly -ParameterFilter {
            $Name -eq 'WindowsUpdateNotificationLevel' -and $Option -eq 'None'
        }
    }
}
