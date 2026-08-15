@{
    AdvertisingId = @{
        DisabledByGroupPolicy = @(
            @{
                Path = 'Registry::HKEY_LOCAL_MACHINE\SOFTWARE\Policies\Microsoft\Windows\AdvertisingInfo'
                Name = 'DisabledByGroupPolicy'
                Type = 'DWord'
                Options = @{
                    Default = @{ Action = 'Remove' }
                    Disabled = @{ Action = 'Set'; Value = 1 }
                }
            }
        )
    }
    AppLaunchTracking = @{
        Start_TrackProgs = @(
            @{
                Path = 'Registry::HKEY_CURRENT_USER\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Advanced'
                Name = 'Start_TrackProgs'
                Type = 'DWord'
                Options = @{
                    Enable = @{ Action = 'Remove' }
                    Disable = @{ Action = 'Set'; Value = 0 }
                }
            }
        )
    }
    AppSuggestions = @{
        SystemPaneSuggestionsEnabled = @(
            @{
                Path = 'Registry::HKEY_CURRENT_USER\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager'
                Name = 'SystemPaneSuggestionsEnabled'
                Type = 'DWord'
                Options = @{
                    Enable = @{ Action = 'Remove' }
                    Disable = @{ Action = 'Set'; Value = 0 }
                }
            }
        )
    }
    DarkMode = @{
        AppsUseLightTheme = @(
            @{
                Path = 'Registry::HKEY_CURRENT_USER\Software\Microsoft\Windows\CurrentVersion\Themes\Personalize'
                Name = 'AppsUseLightTheme'
                Type = 'DWord'
                Options = @{
                    Enable = @{ Action = 'Set'; Value = 0 }
                    Disable = @{ Action = 'Set'; Value = 1 }
                }
            }
        )
        SystemUsesLightTheme = @(
            @{
                Path = 'Registry::HKEY_CURRENT_USER\Software\Microsoft\Windows\CurrentVersion\Themes\Personalize'
                Name = 'SystemUsesLightTheme'
                Type = 'DWord'
                Options = @{
                    Enable = @{ Action = 'Set'; Value = 0 }
                    Disable = @{ Action = 'Set'; Value = 1 }
                }
            }
        )
    }
    EdgeFirstRunExperience = @{
        HideFirstRunExperience = @(
            @{
                Path = 'Registry::HKEY_LOCAL_MACHINE\SOFTWARE\Policies\Microsoft\Edge'
                Name = 'HideFirstRunExperience'
                Type = 'DWord'
                Options = @{
                    Enable = @{ Action = 'Set'; Value = 0 }
                    Disable = @{ Action = 'Set'; Value = 1 }
                }
            }
        )
    }
    FileHistory = @{
        Disabled = @(
            @{
                Path = 'Registry::HKEY_LOCAL_MACHINE\Software\Policies\Microsoft\Windows\FileHistory'
                Name = 'Disabled'
                Type = 'DWord'
                Options = @{
                    Enable = @{ Action = 'Set'; Value = 0 }
                    Disable = @{ Action = 'Set'; Value = 1 }
                }
            }
        )
    }
    LockScreen = @{
        NoLockScreen = @(
            @{
                Path = 'Registry::HKEY_LOCAL_MACHINE\Software\Policies\Microsoft\Windows\Personalization'
                Name = 'NoLockScreen'
                Type = 'DWord'
                Options = @{
                    Enable = @{ Action = 'Set'; Value = 0 }
                    Disable = @{ Action = 'Set'; Value = 1 }
                }
            }
        )
    }
    LockWorkstation = @{
        DisableLockWorkstation = @(
            @{
                Path = 'Registry::HKEY_CURRENT_USER\Software\Microsoft\Windows\CurrentVersion\Policies\System'
                Name = 'DisableLockWorkstation'
                Type = 'DWord'
                Options = @{
                    Enable = @{ Action = 'Set'; Value = 0 }
                    Disable = @{ Action = 'Set'; Value = 1 }
                }
            }
        )
    }
    LongPaths = @{
        LongPathsEnabled = @(
            @{
                Path = 'Registry::HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\FileSystem'
                Name = 'LongPathsEnabled'
                Type = 'DWord'
                Options = @{
                    Enable = @{ Action = 'Set'; Value = 1 }
                    Disable = @{ Action = 'Set'; Value = 0 }
                }
            }
        )
    }
    Widgets = @{
        AllowNewsAndInterests = @(
            @{
                Path = 'Registry::HKEY_LOCAL_MACHINE\SOFTWARE\Policies\Microsoft\Dsh'
                Name = 'AllowNewsAndInterests'
                Type = 'DWord'
                Options = @{
                    Enable = @{ Action = 'Set'; Value = 1 }
                    Disable = @{ Action = 'Set'; Value = 0 }
                }
            }
        )
    }
    RequireSignInOnWakeup = @{
        DCSettingIndex = @(
            @{
                Path = 'Registry::HKEY_LOCAL_MACHINE\Software\Policies\Microsoft\Power\PowerSettings\0e796bdb-100d-47d6-a2d5-f7d2daa51f51'
                Name = 'DCSettingIndex'
                Type = 'DWord'
                Options = @{
                    Enable = @{ Action = 'Set'; Value = 1 }
                    Disable = @{ Action = 'Set'; Value = 0 }
                }
            }
        )
        ACSettingIndex = @(
            @{
                Path = 'Registry::HKEY_LOCAL_MACHINE\Software\Policies\Microsoft\Power\PowerSettings\0e796bdb-100d-47d6-a2d5-f7d2daa51f51'
                Name = 'ACSettingIndex'
                Type = 'DWord'
                Options = @{
                    Enable = @{ Action = 'Set'; Value = 1 }
                    Disable = @{ Action = 'Set'; Value = 0 }
                }
            }
        )
    }
    SaveZoneInformation = @{
        SaveZoneInformation = @(
            @{
                Path = 'Registry::HKEY_CURRENT_USER\Software\Microsoft\Windows\CurrentVersion\Policies\Attachments'
                Name = 'SaveZoneInformation'
                Type = 'DWord'
                Options = @{
                    Enable = @{ Action = 'Remove' }
                    Disable = @{ Action = 'Set'; Value = 1 }
                }
            }
        )
    }
    SmartScreenInShell = @{
        EnableSmartScreen = @(
            @{
                Path = 'Registry::HKEY_LOCAL_MACHINE\Software\Policies\Microsoft\Windows\System'
                Name = 'EnableSmartScreen'
                Type = 'DWord'
                Options = @{
                    Enable = @{ Action = 'Set'; Value = 1 }
                    Disable = @{ Action = 'Set'; Value = 0 }
                }
            }
        )
    }
    Uac = @{
        EnableLUA = @(
            @{
                Path = 'Registry::HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System'
                Name = 'EnableLUA'
                Type = 'DWord'
                Options = @{
                    Enable = @{ Action = 'Set'; Value = 1 }
                    Disable = @{ Action = 'Set'; Value = 0 }
                }
            }
        )
    }
    WebsiteAccessToLanguageList = @{
        HttpAcceptLanguageOptOut = @(
            @{
                Path = 'Registry::HKEY_CURRENT_USER\Control Panel\International\User Profile'
                Name = 'HttpAcceptLanguageOptOut'
                Type = 'DWord'
                Options = @{
                    Enable = @{ Action = 'Remove' }
                    Disable = @{ Action = 'Set'; Value = 1 }
                }
            }
        )
    }
    WindowsHelloForBusiness = @{
        Enabled = @(
            @{
                Path = 'Registry::HKEY_LOCAL_MACHINE\SOFTWARE\Policies\Microsoft\PassportForWork'
                Name = 'Enabled'
                Type = 'DWord'
                Options = @{
                    Enable = @{ Action = 'Set'; Value = 1 }
                    Disable = @{ Action = 'Set'; Value = 0 }
                }
            }
        )
    }
    WindowsMediaPlayerFirstUseDialogBoxes = @{
        GroupPrivacyAcceptance = @(
            @{
                Path = 'Registry::HKEY_LOCAL_MACHINE\Software\Policies\Microsoft\WindowsMediaPlayer'
                Name = 'GroupPrivacyAcceptance'
                Type = 'DWord'
                Options = @{
                    Enable = @{ Action = 'Set'; Value = 0 }
                    Disable = @{ Action = 'Set'; Value = 1 }
                }
            }
        )
    }
    WindowsSecurityAllNotifications = @{
        DisableNotifications = @(
            @{
                Path = 'Registry::HKEY_LOCAL_MACHINE\SOFTWARE\Policies\Microsoft\Windows Defender Security Center\Notifications'
                Name = 'DisableNotifications'
                Type = 'DWord'
                Options = @{
                    Enable = @{ Action = 'Remove' }
                    Disable = @{ Action = 'Set'; Value = 1 }
                }
            }
        )
    }
    WindowsSecurityNonCriticalNotifications = @{
        DisableEnhancedNotifications = @(
            @{
                Path = 'Registry::HKEY_LOCAL_MACHINE\SOFTWARE\Policies\Microsoft\Windows Defender Security Center\Notifications'
                Name = 'DisableEnhancedNotifications'
                Type = 'DWord'
                Options = @{
                    Enable = @{ Action = 'Remove' }
                    Disable = @{ Action = 'Set'; Value = 1 }
                }
            }
        )
    }
    WindowsUpdateNotificationLevel = @{
        SetUpdateNotificationLevel = @(
            @{
                Path = 'Registry::HKEY_LOCAL_MACHINE\Software\Policies\Microsoft\Windows\WindowsUpdate'
                Name = 'SetUpdateNotificationLevel'
                Type = 'DWord'
                Options = @{
                    Default = @{ Action = 'Remove' }
                    RestartWarningsOnly = @{ Action = 'Set'; Value = 1 }
                    None = @{ Action = 'Set'; Value = 1 }
                }
            }
        )
        UpdateNotificationLevel = @(
            @{
                Path = 'Registry::HKEY_LOCAL_MACHINE\Software\Policies\Microsoft\Windows\WindowsUpdate'
                Name = 'UpdateNotificationLevel'
                Type = 'DWord'
                Options = @{
                    Default = @{ Action = 'Remove' }
                    RestartWarningsOnly = @{ Action = 'Set'; Value = 1 }
                    None = @{ Action = 'Set'; Value = 2 }
                }
            }
        )
    }
}
