@{
    AdvertisingId = @{
        Properties = @{
            DisabledByGroupPolicy = @{
                Path = 'Registry::HKEY_LOCAL_MACHINE\SOFTWARE\Policies\Microsoft\Windows\AdvertisingInfo'
                Type = 'DWord'
            }
        }
        Options = @{
            Default = @{
                DisabledByGroupPolicy = @{ Action = 'Remove' }
            }
            Disabled = @{
                DisabledByGroupPolicy = @{ Action = 'Set'; Value = 1 }
            }
        }
    }
    AppLaunchTracking = @{
        Properties = @{
            Start_TrackProgs = @{
                Path = 'Registry::HKEY_CURRENT_USER\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Advanced'
                Type = 'DWord'
            }
        }
        Options = @{
            Enable = @{
                Start_TrackProgs = @{ Action = 'Remove' }
            }
            Disable = @{
                Start_TrackProgs = @{ Action = 'Set'; Value = 0 }
            }
        }
    }
    AppSuggestions = @{
        Properties = @{
            SystemPaneSuggestionsEnabled = @{
                Path = 'Registry::HKEY_CURRENT_USER\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager'
                Type = 'DWord'
            }
        }
        Options = @{
            Enable = @{
                SystemPaneSuggestionsEnabled = @{ Action = 'Remove' }
            }
            Disable = @{
                SystemPaneSuggestionsEnabled = @{ Action = 'Set'; Value = 0 }
            }
        }
    }
    DarkMode = @{
        Properties = @{
            AppsUseLightTheme = @{
                Path = 'Registry::HKEY_CURRENT_USER\Software\Microsoft\Windows\CurrentVersion\Themes\Personalize'
                Type = 'DWord'
            }
            SystemUsesLightTheme = @{
                Path = 'Registry::HKEY_CURRENT_USER\Software\Microsoft\Windows\CurrentVersion\Themes\Personalize'
                Type = 'DWord'
            }
        }
        Options = @{
            Enable = @{
                AppsUseLightTheme = @{ Action = 'Set'; Value = 0 }
                SystemUsesLightTheme = @{ Action = 'Set'; Value = 0 }
            }
            Disable = @{
                AppsUseLightTheme = @{ Action = 'Set'; Value = 1 }
                SystemUsesLightTheme = @{ Action = 'Set'; Value = 1 }
            }
        }
    }
    EdgeFirstRunExperience = @{
        Properties = @{
            HideFirstRunExperience = @{
                Path = 'Registry::HKEY_LOCAL_MACHINE\SOFTWARE\Policies\Microsoft\Edge'
                Type = 'DWord'
            }
        }
        Options = @{
            Enable = @{
                HideFirstRunExperience = @{ Action = 'Set'; Value = 0 }
            }
            Disable = @{
                HideFirstRunExperience = @{ Action = 'Set'; Value = 1 }
            }
        }
    }
    FileHistory = @{
        Properties = @{
            Disabled = @{
                Path = 'Registry::HKEY_LOCAL_MACHINE\Software\Policies\Microsoft\Windows\FileHistory'
                Type = 'DWord'
            }
        }
        Options = @{
            Enable = @{
                Disabled = @{ Action = 'Set'; Value = 0 }
            }
            Disable = @{
                Disabled = @{ Action = 'Set'; Value = 1 }
            }
        }
    }
    LockScreen = @{
        Properties = @{
            NoLockScreen = @{
                Path = 'Registry::HKEY_LOCAL_MACHINE\Software\Policies\Microsoft\Windows\Personalization'
                Type = 'DWord'
            }
        }
        Options = @{
            Enable = @{
                NoLockScreen = @{ Action = 'Set'; Value = 0 }
            }
            Disable = @{
                NoLockScreen = @{ Action = 'Set'; Value = 1 }
            }
        }
    }
    LockWorkstation = @{
        Properties = @{
            DisableLockWorkstation = @{
                Path = 'Registry::HKEY_CURRENT_USER\Software\Microsoft\Windows\CurrentVersion\Policies\System'
                Type = 'DWord'
            }
        }
        Options = @{
            Enable = @{
                DisableLockWorkstation = @{ Action = 'Set'; Value = 0 }
            }
            Disable = @{
                DisableLockWorkstation = @{ Action = 'Set'; Value = 1 }
            }
        }
    }
    LongPaths = @{
        Properties = @{
            LongPathsEnabled = @{
                Path = 'Registry::HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\FileSystem'
                Type = 'DWord'
            }
        }
        Options = @{
            Enable = @{
                LongPathsEnabled = @{ Action = 'Set'; Value = 1 }
            }
            Disable = @{
                LongPathsEnabled = @{ Action = 'Set'; Value = 0 }
            }
        }
    }
    Widgets = @{
        Properties = @{
            AllowNewsAndInterests = @{
                Path = 'Registry::HKEY_LOCAL_MACHINE\SOFTWARE\Policies\Microsoft\Dsh'
                Type = 'DWord'
            }
        }
        Options = @{
            Enable = @{
                AllowNewsAndInterests = @{ Action = 'Set'; Value = 1 }
            }
            Disable = @{
                AllowNewsAndInterests = @{ Action = 'Set'; Value = 0 }
            }
        }
    }
    RequireSignInOnWakeup = @{
        Properties = @{
            DCSettingIndex = @{
                Path = 'Registry::HKEY_LOCAL_MACHINE\Software\Policies\Microsoft\Power\PowerSettings\0e796bdb-100d-47d6-a2d5-f7d2daa51f51'
                Type = 'DWord'
            }
            ACSettingIndex = @{
                Path = 'Registry::HKEY_LOCAL_MACHINE\Software\Policies\Microsoft\Power\PowerSettings\0e796bdb-100d-47d6-a2d5-f7d2daa51f51'
                Type = 'DWord'
            }
        }
        Options = @{
            Enable = @{
                DCSettingIndex = @{ Action = 'Set'; Value = 1 }
                ACSettingIndex = @{ Action = 'Set'; Value = 1 }
            }
            Disable = @{
                DCSettingIndex = @{ Action = 'Set'; Value = 0 }
                ACSettingIndex = @{ Action = 'Set'; Value = 0 }
            }
        }
    }
    SaveZoneInformation = @{
        Properties = @{
            SaveZoneInformation = @{
                Path = 'Registry::HKEY_CURRENT_USER\Software\Microsoft\Windows\CurrentVersion\Policies\Attachments'
                Type = 'DWord'
            }
        }
        Options = @{
            Enable = @{
                SaveZoneInformation = @{ Action = 'Remove' }
            }
            Disable = @{
                SaveZoneInformation = @{ Action = 'Set'; Value = 1 }
            }
        }
    }
    SmartScreenInShell = @{
        Properties = @{
            EnableSmartScreen = @{
                Path = 'Registry::HKEY_LOCAL_MACHINE\Software\Policies\Microsoft\Windows\System'
                Type = 'DWord'
            }
        }
        Options = @{
            Enable = @{
                EnableSmartScreen = @{ Action = 'Set'; Value = 1 }
            }
            Disable = @{
                EnableSmartScreen = @{ Action = 'Set'; Value = 0 }
            }
        }
    }
    Uac = @{
        Properties = @{
            EnableLUA = @{
                Path = 'Registry::HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System'
                Type = 'DWord'
            }
        }
        Options = @{
            Enable = @{
                EnableLUA = @{ Action = 'Set'; Value = 1 }
            }
            Disable = @{
                EnableLUA = @{ Action = 'Set'; Value = 0 }
            }
        }
    }
    WebsiteAccessToLanguageList = @{
        Properties = @{
            HttpAcceptLanguageOptOut = @{
                Path = 'Registry::HKEY_CURRENT_USER\Control Panel\International\User Profile'
                Type = 'DWord'
            }
        }
        Options = @{
            Enable = @{
                HttpAcceptLanguageOptOut = @{ Action = 'Remove' }
            }
            Disable = @{
                HttpAcceptLanguageOptOut = @{ Action = 'Set'; Value = 1 }
            }
        }
    }
    WindowsHelloForBusiness = @{
        Properties = @{
            Enabled = @{
                Path = 'Registry::HKEY_LOCAL_MACHINE\SOFTWARE\Policies\Microsoft\PassportForWork'
                Type = 'DWord'
            }
        }
        Options = @{
            Enable = @{
                Enabled = @{ Action = 'Set'; Value = 1 }
            }
            Disable = @{
                Enabled = @{ Action = 'Set'; Value = 0 }
            }
        }
    }
    WindowsMediaPlayerFirstUseDialogBoxes = @{
        Properties = @{
            GroupPrivacyAcceptance = @{
                Path = 'Registry::HKEY_LOCAL_MACHINE\Software\Policies\Microsoft\WindowsMediaPlayer'
                Type = 'DWord'
            }
        }
        Options = @{
            Enable = @{
                GroupPrivacyAcceptance = @{ Action = 'Set'; Value = 0 }
            }
            Disable = @{
                GroupPrivacyAcceptance = @{ Action = 'Set'; Value = 1 }
            }
        }
    }
    WindowsSecurityAllNotifications = @{
        Properties = @{
            DisableNotifications = @{
                Path = 'Registry::HKEY_LOCAL_MACHINE\SOFTWARE\Policies\Microsoft\Windows Defender Security Center\Notifications'
                Type = 'DWord'
            }
        }
        Options = @{
            Enable = @{
                DisableNotifications = @{ Action = 'Remove' }
            }
            Disable = @{
                DisableNotifications = @{ Action = 'Set'; Value = 1 }
            }
        }
    }
    WindowsSecurityNonCriticalNotifications = @{
        Properties = @{
            DisableEnhancedNotifications = @{
                Path = 'Registry::HKEY_LOCAL_MACHINE\SOFTWARE\Policies\Microsoft\Windows Defender Security Center\Notifications'
                Type = 'DWord'
            }
        }
        Options = @{
            Enable = @{
                DisableEnhancedNotifications = @{ Action = 'Remove' }
            }
            Disable = @{
                DisableEnhancedNotifications = @{ Action = 'Set'; Value = 1 }
            }
        }
    }
    WindowsUpdateNotificationLevel = @{
        Properties = @{
            SetUpdateNotificationLevel = @{
                Path = 'Registry::HKEY_LOCAL_MACHINE\Software\Policies\Microsoft\Windows\WindowsUpdate'
                Type = 'DWord'
            }
            UpdateNotificationLevel = @{
                Path = 'Registry::HKEY_LOCAL_MACHINE\Software\Policies\Microsoft\Windows\WindowsUpdate'
                Type = 'DWord'
            }
        }
        Options = @{
            Default = @{
                SetUpdateNotificationLevel = @{ Action = 'Remove' }
                UpdateNotificationLevel = @{ Action = 'Remove' }
            }
            RestartWarningsOnly = @{
                SetUpdateNotificationLevel = @{ Action = 'Set'; Value = 1 }
                UpdateNotificationLevel = @{ Action = 'Set'; Value = 1 }
            }
            None = @{
                SetUpdateNotificationLevel = @{ Action = 'Set'; Value = 1 }
                UpdateNotificationLevel = @{ Action = 'Set'; Value = 2 }
            }
        }
    }
    DeviceSetupSuggestions = @{
        Properties = @{
            ScoobeSystemSettingEnabled = @{
                Path = 'Registry::HKEY_CURRENT_USER\Software\Microsoft\Windows\CurrentVersion\UserProfileEngagement'
                Type = 'DWord'
            }
        }
        Options = @{
            Enable = @{
                ScoobeSystemSettingEnabled = @{ Action = 'Set'; Value = 1 }
            }
            Disable = @{
                ScoobeSystemSettingEnabled = @{ Action = 'Set'; Value = 0 }
            }
        }
    }
    TaskbarAlignment = @{
        Properties = @{
            TaskbarAl = @{
                Path = 'Registry::HKEY_CURRENT_USER\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Advanced'
                Type = 'DWord'
            }
        }
        Options = @{
            Left = @{
                TaskbarAl = @{ Action = 'Set'; Value = 0 }
            }
            Center = @{
                TaskbarAl = @{ Action = 'Set'; Value = 1 }
            }
        }
    }
    TaskbarSearchMode = @{
        Properties = @{
            SearchboxTaskbarMode = @{
                Path = 'Registry::HKEY_CURRENT_USER\SOFTWARE\Microsoft\Windows\CurrentVersion\Search'
                Type = 'DWord'
            }
        }
        Options = @{
            Hidden = @{
                SearchboxTaskbarMode = @{ Action = 'Set'; Value = 0 }
            }
            Icon = @{
                SearchboxTaskbarMode = @{ Action = 'Set'; Value = 1 }
            }
            SearchBox = @{
                SearchboxTaskbarMode = @{ Action = 'Set'; Value = 2 }
            }
        }
    }
    JapaneseImeHalfWidthInput = @{
        Properties = @{
            SpaceInputMode = @{
                Path = 'Registry::HKEY_CURRENT_USER\SOFTWARE\Microsoft\IME\15.0\IMJP\Settings'
                Type = 'DWord'
            }
            NumInputMode = @{
                Path = 'Registry::HKEY_CURRENT_USER\SOFTWARE\Microsoft\IME\15.0\IMJP\Settings'
                Type = 'DWord'
            }
            AlphabetInputMode = @{
                Path = 'Registry::HKEY_CURRENT_USER\SOFTWARE\Microsoft\IME\15.0\IMJP\Settings'
                Type = 'DWord'
            }
        }
        Options = @{
            Set = @{
                SpaceInputMode = @{ Action = 'Set'; Value = 0 }
                NumInputMode = @{ Action = 'Set'; Value = 0 }
                AlphabetInputMode = @{ Action = 'Set'; Value = 0 }
            }
        }
    }
}
