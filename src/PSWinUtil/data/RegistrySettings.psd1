@{
    Settings = @(
        @{
            Name = 'AdvertisingId'
            Configurations = @(
                @{
                    Scope = 'Machine'
                    Properties = @(
                        @{
                            Name = 'DisabledByGroupPolicy'
                            Path = 'Registry::HKEY_LOCAL_MACHINE\SOFTWARE\Policies\Microsoft\Windows\AdvertisingInfo'
                            Type = 'DWord'
                            Options = @(
                                @{
                                    Name = 'Default'
                                    Action = 'Remove'
                                }
                                @{
                                    Name = 'Disabled'
                                    Action = 'Set'
                                    Value = 1
                                }
                            )
                        }
                    )
                }
            )
        }
        @{
            Name = 'AppLaunchTracking'
            Configurations = @(
                @{
                    Scope = 'User'
                    Properties = @(
                        @{
                            Name = 'Start_TrackProgs'
                            Path = 'Registry::HKEY_CURRENT_USER\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Advanced'
                            Type = 'DWord'
                            Options = @(
                                @{
                                    Name = 'Enable'
                                    Action = 'Remove'
                                }
                                @{
                                    Name = 'Disable'
                                    Action = 'Set'
                                    Value = 0
                                }
                            )
                        }
                    )
                }
            )
        }
        @{
            Name = 'AppSuggestions'
            Configurations = @(
                @{
                    Scope = 'User'
                    Properties = @(
                        @{
                            Name = 'SystemPaneSuggestionsEnabled'
                            Path = 'Registry::HKEY_CURRENT_USER\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager'
                            Type = 'DWord'
                            Options = @(
                                @{
                                    Name = 'Enable'
                                    Action = 'Remove'
                                }
                                @{
                                    Name = 'Disable'
                                    Action = 'Set'
                                    Value = 0
                                }
                            )
                        }
                    )
                }
            )
        }
        @{
            Name = 'DarkMode'
            Configurations = @(
                @{
                    Scope = 'User'
                    Properties = @(
                        @{
                            Name = 'AppsUseLightTheme'
                            Path = 'Registry::HKEY_CURRENT_USER\Software\Microsoft\Windows\CurrentVersion\Themes\Personalize'
                            Type = 'DWord'
                            Options = @(
                                @{
                                    Name = 'Enable'
                                    Action = 'Set'
                                    Value = 0
                                }
                                @{
                                    Name = 'Disable'
                                    Action = 'Set'
                                    Value = 1
                                }
                            )
                        }
                        @{
                            Name = 'SystemUsesLightTheme'
                            Path = 'Registry::HKEY_CURRENT_USER\Software\Microsoft\Windows\CurrentVersion\Themes\Personalize'
                            Type = 'DWord'
                            Options = @(
                                @{
                                    Name = 'Enable'
                                    Action = 'Set'
                                    Value = 0
                                }
                                @{
                                    Name = 'Disable'
                                    Action = 'Set'
                                    Value = 1
                                }
                            )
                        }
                    )
                }
            )
        }
        @{
            Name = 'EdgeFirstRunExperience'
            Configurations = @(
                @{
                    Scope = 'Machine'
                    Properties = @(
                        @{
                            Name = 'HideFirstRunExperience'
                            Path = 'Registry::HKEY_LOCAL_MACHINE\SOFTWARE\Policies\Microsoft\Edge'
                            Type = 'DWord'
                            Options = @(
                                @{
                                    Name = 'Enable'
                                    Action = 'Set'
                                    Value = 0
                                }
                                @{
                                    Name = 'Disable'
                                    Action = 'Set'
                                    Value = 1
                                }
                            )
                        }
                    )
                }
            )
        }
        @{
            Name = 'FileHistory'
            Configurations = @(
                @{
                    Scope = 'Machine'
                    Properties = @(
                        @{
                            Name = 'Disabled'
                            Path = 'Registry::HKEY_LOCAL_MACHINE\Software\Policies\Microsoft\Windows\FileHistory'
                            Type = 'DWord'
                            Options = @(
                                @{
                                    Name = 'Enable'
                                    Action = 'Set'
                                    Value = 0
                                }
                                @{
                                    Name = 'Disable'
                                    Action = 'Set'
                                    Value = 1
                                }
                            )
                        }
                    )
                }
            )
        }
        @{
            Name = 'LockScreen'
            Configurations = @(
                @{
                    Scope = 'Machine'
                    Properties = @(
                        @{
                            Name = 'NoLockScreen'
                            Path = 'Registry::HKEY_LOCAL_MACHINE\Software\Policies\Microsoft\Windows\Personalization'
                            Type = 'DWord'
                            Options = @(
                                @{
                                    Name = 'Enable'
                                    Action = 'Set'
                                    Value = 0
                                }
                                @{
                                    Name = 'Disable'
                                    Action = 'Set'
                                    Value = 1
                                }
                            )
                        }
                    )
                }
            )
        }
        @{
            Name = 'LockWorkstation'
            Configurations = @(
                @{
                    Scope = 'User'
                    Properties = @(
                        @{
                            Name = 'DisableLockWorkstation'
                            Path = 'Registry::HKEY_CURRENT_USER\Software\Microsoft\Windows\CurrentVersion\Policies\System'
                            Type = 'DWord'
                            Options = @(
                                @{
                                    Name = 'Enable'
                                    Action = 'Set'
                                    Value = 0
                                }
                                @{
                                    Name = 'Disable'
                                    Action = 'Set'
                                    Value = 1
                                }
                            )
                        }
                    )
                }
            )
        }
        @{
            Name = 'LongPaths'
            Configurations = @(
                @{
                    Scope = 'Machine'
                    Properties = @(
                        @{
                            Name = 'LongPathsEnabled'
                            Path = 'Registry::HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\FileSystem'
                            Type = 'DWord'
                            Options = @(
                                @{
                                    Name = 'Enable'
                                    Action = 'Set'
                                    Value = 1
                                }
                                @{
                                    Name = 'Disable'
                                    Action = 'Set'
                                    Value = 0
                                }
                            )
                        }
                    )
                }
            )
        }
        @{
            Name = 'Widgets'
            Configurations = @(
                @{
                    Scope = 'Machine'
                    Properties = @(
                        @{
                            Name = 'AllowNewsAndInterests'
                            Path = 'Registry::HKEY_LOCAL_MACHINE\SOFTWARE\Policies\Microsoft\Dsh'
                            Type = 'DWord'
                            Options = @(
                                @{
                                    Name = 'Enable'
                                    Action = 'Set'
                                    Value = 1
                                }
                                @{
                                    Name = 'Disable'
                                    Action = 'Set'
                                    Value = 0
                                }
                            )
                        }
                    )
                }
            )
        }
        @{
            Name = 'RequireSignInOnWakeup'
            Configurations = @(
                @{
                    Scope = 'Machine'
                    Properties = @(
                        @{
                            Name = 'DCSettingIndex'
                            Path = 'Registry::HKEY_LOCAL_MACHINE\Software\Policies\Microsoft\Power\PowerSettings\0e796bdb-100d-47d6-a2d5-f7d2daa51f51'
                            Type = 'DWord'
                            Options = @(
                                @{
                                    Name = 'Enable'
                                    Action = 'Set'
                                    Value = 1
                                }
                                @{
                                    Name = 'Disable'
                                    Action = 'Set'
                                    Value = 0
                                }
                            )
                        }
                        @{
                            Name = 'ACSettingIndex'
                            Path = 'Registry::HKEY_LOCAL_MACHINE\Software\Policies\Microsoft\Power\PowerSettings\0e796bdb-100d-47d6-a2d5-f7d2daa51f51'
                            Type = 'DWord'
                            Options = @(
                                @{
                                    Name = 'Enable'
                                    Action = 'Set'
                                    Value = 1
                                }
                                @{
                                    Name = 'Disable'
                                    Action = 'Set'
                                    Value = 0
                                }
                            )
                        }
                    )
                }
            )
        }
        @{
            Name = 'SaveZoneInformation'
            Configurations = @(
                @{
                    Scope = 'User'
                    Properties = @(
                        @{
                            Name = 'SaveZoneInformation'
                            Path = 'Registry::HKEY_CURRENT_USER\Software\Microsoft\Windows\CurrentVersion\Policies\Attachments'
                            Type = 'DWord'
                            Options = @(
                                @{
                                    Name = 'Enable'
                                    Action = 'Remove'
                                }
                                @{
                                    Name = 'Disable'
                                    Action = 'Set'
                                    Value = 1
                                }
                            )
                        }
                    )
                }
            )
        }
        @{
            Name = 'SmartScreenInShell'
            Configurations = @(
                @{
                    Scope = 'Machine'
                    Properties = @(
                        @{
                            Name = 'EnableSmartScreen'
                            Path = 'Registry::HKEY_LOCAL_MACHINE\Software\Policies\Microsoft\Windows\System'
                            Type = 'DWord'
                            Options = @(
                                @{
                                    Name = 'Enable'
                                    Action = 'Set'
                                    Value = 1
                                }
                                @{
                                    Name = 'Disable'
                                    Action = 'Set'
                                    Value = 0
                                }
                            )
                        }
                    )
                }
            )
        }
        @{
            Name = 'Uac'
            Configurations = @(
                @{
                    Scope = 'Machine'
                    Properties = @(
                        @{
                            Name = 'EnableLUA'
                            Path = 'Registry::HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System'
                            Type = 'DWord'
                            Options = @(
                                @{
                                    Name = 'Enable'
                                    Action = 'Set'
                                    Value = 1
                                }
                                @{
                                    Name = 'Disable'
                                    Action = 'Set'
                                    Value = 0
                                }
                            )
                        }
                    )
                }
            )
        }
        @{
            Name = 'WebsiteAccessToLanguageList'
            Configurations = @(
                @{
                    Scope = 'User'
                    Properties = @(
                        @{
                            Name = 'HttpAcceptLanguageOptOut'
                            Path = 'Registry::HKEY_CURRENT_USER\Control Panel\International\User Profile'
                            Type = 'DWord'
                            Options = @(
                                @{
                                    Name = 'Enable'
                                    Action = 'Remove'
                                }
                                @{
                                    Name = 'Disable'
                                    Action = 'Set'
                                    Value = 1
                                }
                            )
                        }
                    )
                }
            )
        }
        @{
            Name = 'WindowsHelloForBusiness'
            Configurations = @(
                @{
                    Scope = 'Machine'
                    Properties = @(
                        @{
                            Name = 'Enabled'
                            Path = 'Registry::HKEY_LOCAL_MACHINE\SOFTWARE\Policies\Microsoft\PassportForWork'
                            Type = 'DWord'
                            Options = @(
                                @{
                                    Name = 'Enable'
                                    Action = 'Set'
                                    Value = 1
                                }
                                @{
                                    Name = 'Disable'
                                    Action = 'Set'
                                    Value = 0
                                }
                            )
                        }
                    )
                }
            )
        }
        @{
            Name = 'WindowsMediaPlayerFirstUseDialogBoxes'
            Configurations = @(
                @{
                    Scope = 'Machine'
                    Properties = @(
                        @{
                            Name = 'GroupPrivacyAcceptance'
                            Path = 'Registry::HKEY_LOCAL_MACHINE\Software\Policies\Microsoft\WindowsMediaPlayer'
                            Type = 'DWord'
                            Options = @(
                                @{
                                    Name = 'Enable'
                                    Action = 'Set'
                                    Value = 0
                                }
                                @{
                                    Name = 'Disable'
                                    Action = 'Set'
                                    Value = 1
                                }
                            )
                        }
                    )
                }
            )
        }
        @{
            Name = 'WindowsSecurityAllNotifications'
            Configurations = @(
                @{
                    Scope = 'Machine'
                    Properties = @(
                        @{
                            Name = 'DisableNotifications'
                            Path = 'Registry::HKEY_LOCAL_MACHINE\SOFTWARE\Policies\Microsoft\Windows Defender Security Center\Notifications'
                            Type = 'DWord'
                            Options = @(
                                @{
                                    Name = 'Enable'
                                    Action = 'Remove'
                                }
                                @{
                                    Name = 'Disable'
                                    Action = 'Set'
                                    Value = 1
                                }
                            )
                        }
                    )
                }
            )
        }
        @{
            Name = 'WindowsSecurityNonCriticalNotifications'
            Configurations = @(
                @{
                    Scope = 'Machine'
                    Properties = @(
                        @{
                            Name = 'DisableEnhancedNotifications'
                            Path = 'Registry::HKEY_LOCAL_MACHINE\SOFTWARE\Policies\Microsoft\Windows Defender Security Center\Notifications'
                            Type = 'DWord'
                            Options = @(
                                @{
                                    Name = 'Enable'
                                    Action = 'Remove'
                                }
                                @{
                                    Name = 'Disable'
                                    Action = 'Set'
                                    Value = 1
                                }
                            )
                        }
                    )
                }
            )
        }
        @{
            Name = 'WindowsUpdateNotificationLevel'
            Configurations = @(
                @{
                    Scope = 'Machine'
                    Properties = @(
                        @{
                            Name = 'SetUpdateNotificationLevel'
                            Path = 'Registry::HKEY_LOCAL_MACHINE\Software\Policies\Microsoft\Windows\WindowsUpdate'
                            Type = 'DWord'
                            Options = @(
                                @{
                                    Name = 'Default'
                                    Action = 'Remove'
                                }
                                @{
                                    Name = 'RestartWarningsOnly'
                                    Action = 'Set'
                                    Value = 1
                                }
                                @{
                                    Name = 'None'
                                    Action = 'Set'
                                    Value = 1
                                }
                            )
                        }
                        @{
                            Name = 'UpdateNotificationLevel'
                            Path = 'Registry::HKEY_LOCAL_MACHINE\Software\Policies\Microsoft\Windows\WindowsUpdate'
                            Type = 'DWord'
                            Options = @(
                                @{
                                    Name = 'Default'
                                    Action = 'Remove'
                                }
                                @{
                                    Name = 'RestartWarningsOnly'
                                    Action = 'Set'
                                    Value = 1
                                }
                                @{
                                    Name = 'None'
                                    Action = 'Set'
                                    Value = 2
                                }
                            )
                        }
                    )
                }
            )
        }
        @{
            Name = 'DeviceSetupSuggestions'
            Configurations = @(
                @{
                    Scope = 'User'
                    Properties = @(
                        @{
                            Name = 'ScoobeSystemSettingEnabled'
                            Path = 'Registry::HKEY_CURRENT_USER\Software\Microsoft\Windows\CurrentVersion\UserProfileEngagement'
                            Type = 'DWord'
                            Options = @(
                                @{
                                    Name = 'Enable'
                                    Action = 'Set'
                                    Value = 1
                                }
                                @{
                                    Name = 'Disable'
                                    Action = 'Set'
                                    Value = 0
                                }
                            )
                        }
                    )
                }
            )
        }
        @{
            Name = 'TaskbarAlignment'
            Configurations = @(
                @{
                    Scope = 'User'
                    Properties = @(
                        @{
                            Name = 'TaskbarAl'
                            Path = 'Registry::HKEY_CURRENT_USER\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Advanced'
                            Type = 'DWord'
                            Options = @(
                                @{
                                    Name = 'Left'
                                    Action = 'Set'
                                    Value = 0
                                }
                                @{
                                    Name = 'Center'
                                    Action = 'Set'
                                    Value = 1
                                }
                            )
                        }
                    )
                }
            )
        }
        @{
            Name = 'TaskbarSearchMode'
            Configurations = @(
                @{
                    Scope = 'User'
                    Properties = @(
                        @{
                            Name = 'SearchboxTaskbarMode'
                            Path = 'Registry::HKEY_CURRENT_USER\SOFTWARE\Microsoft\Windows\CurrentVersion\Search'
                            Type = 'DWord'
                            Options = @(
                                @{
                                    Name = 'Hidden'
                                    Action = 'Set'
                                    Value = 0
                                }
                                @{
                                    Name = 'Icon'
                                    Action = 'Set'
                                    Value = 1
                                }
                                @{
                                    Name = 'SearchBox'
                                    Action = 'Set'
                                    Value = 2
                                }
                            )
                        }
                    )
                }
            )
        }
        @{
            Name = 'JapaneseImeHalfWidthInput'
            Configurations = @(
                @{
                    Scope = 'User'
                    Properties = @(
                        @{
                            Name = 'SpaceInputMode'
                            Path = 'Registry::HKEY_CURRENT_USER\SOFTWARE\Microsoft\IME\15.0\IMJP\Settings'
                            Type = 'DWord'
                            Options = @(
                                @{
                                    Name = 'Set'
                                    Action = 'Set'
                                    Value = 0
                                }
                            )
                        }
                        @{
                            Name = 'NumInputMode'
                            Path = 'Registry::HKEY_CURRENT_USER\SOFTWARE\Microsoft\IME\15.0\IMJP\Settings'
                            Type = 'DWord'
                            Options = @(
                                @{
                                    Name = 'Set'
                                    Action = 'Set'
                                    Value = 0
                                }
                            )
                        }
                        @{
                            Name = 'AlphabetInputMode'
                            Path = 'Registry::HKEY_CURRENT_USER\SOFTWARE\Microsoft\IME\15.0\IMJP\Settings'
                            Type = 'DWord'
                            Options = @(
                                @{
                                    Name = 'Set'
                                    Action = 'Set'
                                    Value = 0
                                }
                            )
                        }
                    )
                }
            )
        }
    )
}
