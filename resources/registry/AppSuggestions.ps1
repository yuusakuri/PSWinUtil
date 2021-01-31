# Application suggestions and automatic installation
@{
    PreInstalledAppsEnabled            = @{
        CurrentUser = @{
            Keyname   = 'HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\ContentDeliveryManager'
            Valuename = 'PreInstalledAppsEnabled'
            Type      = 'REG_DWORD'
            Data      = @{
                Enable  = 1
                Disable = 0
            }
        }
    }
    PreInstalledAppsEverEnabled        = @{
        CurrentUser = @{
            Keyname   = 'HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\ContentDeliveryManager'
            Valuename = 'PreInstalledAppsEverEnabled'
            Type      = 'REG_DWORD'
            Data      = @{
                Enable  = 1
                Disable = 0
            }
        }
    }
    OEMPreInstalledAppsEnabled         = @{
        CurrentUser = @{
            Keyname   = 'HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\ContentDeliveryManager'
            Valuename = 'OEMPreInstalledAppsEnabled'
            Type      = 'REG_DWORD'
            Data      = @{
                Enable  = 1
                Disable = 0
            }
        }
    }
    SilentInstalledAppsEnabled         = @{
        CurrentUser = @{
            Keyname   = 'HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\ContentDeliveryManager'
            Valuename = 'SilentInstalledAppsEnabled'
            Type      = 'REG_DWORD'
            Data      = @{
                Enable  = 1
                Disable = 0
            }
        }
    }
    ContentDeliveryAllowed             = @{
        CurrentUser = @{
            Keyname   = 'HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\ContentDeliveryManager'
            Valuename = 'ContentDeliveryAllowed'
            Type      = 'REG_DWORD'
            Data      = @{
                Enable  = 1
                Disable = 0
            }
        }
    }
    SubscribedContentEnabled           = @{
        CurrentUser = @{
            Keyname   = 'HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\ContentDeliveryManager'
            Valuename = 'SubscribedContentEnabled'
            Type      = 'REG_DWORD'
            Data      = @{
                Enable  = 1
                Disable = 0
            }
        }
    }
    SuggestedContentInSettings1        = @{
        CurrentUser = @{
            Keyname   = 'HKEY_CURRENT_USER\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager'
            Valuename = 'SubscribedContent-338393Enabled'
            Type      = 'REG_DWORD'
            Data      = @{
                Enable  = 1
                Disable = 0
            }
        }
    }
    SuggestedContentInSettings2        = @{
        CurrentUser = @{
            Keyname   = 'HKEY_CURRENT_USER\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager'
            Valuename = 'SubscribedContent-353694Enabled'
            Type      = 'REG_DWORD'
            Data      = @{
                Enable  = 1
                Disable = 0
            }
        }
    }
    SuggestedContentInSettings3        = @{
        CurrentUser = @{
            Keyname   = 'HKEY_CURRENT_USER\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager'
            Valuename = 'SubscribedContent-353696Enabled'
            Type      = 'REG_DWORD'
            Data      = @{
                Enable  = 1
                Disable = 0
            }
        }
    }
    WindowsWelcomeExperience           = @{
        CurrentUser = @{
            Keyname   = 'HKCU\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager'
            Valuename = 'SubscribedContent-310093Enabled'
            Type      = 'REG_DWORD'
            Data      = @{
                Enable  = 1
                Disable = 0
            }
        }
    }
    SubscribedContent314559Enabled     = @{
        CurrentUser = @{
            Keyname   = 'HKCU\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager'
            Valuename = 'SubscribedContent-314559Enabled'
            Type      = 'REG_DWORD'
            Data      = @{
                Enable  = 1
                Disable = 0
            }
        }
    }
    ShowTipsOnTheLockScreen            = @{
        CurrentUser = @{
            Keyname   = 'HKCU\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager'
            Valuename = 'SubscribedContent-338387Enabled'
            Type      = 'REG_DWORD'
            Data      = @{
                Enable  = 1
                Disable = 0
            }
        }
    }
    AppSuggestionsInStart              = @{
        CurrentUser = @{
            Keyname   = 'HKCU\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager'
            Valuename = 'SubscribedContent-338388Enabled'
            Type      = 'REG_DWORD'
            Data      = @{
                Enable  = 1
                Disable = 0
            }
        }
    }
    AppSuggestionsInStartOld           = @{
        CurrentUser = @{
            Keyname   = 'HKEY_CURRENT_USER\SOFTWARE\Microsoft\Windows\CurrentVersion\ContentDeliveryManager'
            Valuename = 'SystemPaneSuggestionsEnabled'
            Type      = 'REG_DWORD'
            Data      = @{
                Enable  = 1
                Disable = 0
            }
        }
    }
    GetTipsAndTricksAndSuggestions     = @{
        CurrentUser = @{
            Keyname   = 'HKEY_CURRENT_USER\SOFTWARE\Microsoft\Windows\CurrentVersion\ContentDeliveryManager'
            Valuename = 'SubscribedContent-338389Enabled'
            Type      = 'REG_DWORD'
            Data      = @{
                Enable  = 1
                Disable = 0
            }
        }
    }
    TimelineSuggestions                = @{
        CurrentUser = @{
            Keyname   = 'HKEY_CURRENT_USER\SOFTWARE\Microsoft\Windows\CurrentVersion\ContentDeliveryManager'
            Valuename = 'SubscribedContent-353698Enabled'
            Type      = 'REG_DWORD'
            Data      = @{
                Enable  = 1
                Disable = 0
            }
        }
    }
    GetEvenMoreOutOfWindows            = @{
        CurrentUser = @{
            Keyname   = 'HKCU\Software\Microsoft\Windows\CurrentVersion\UserProfileEngagement'
            Valuename = 'ScoobeSystemSettingEnabled'
            Type      = 'REG_DWORD'
            Data      = @{
                Enable  = 1
                Disable = 0
            }
        }
    }
    SuggestedAppsInWindowsInkWorkspace = @{
        CurrentUser = @{
            Keyname   = 'HKLM\SOFTWARE\Policies\Microsoft\WindowsInkWorkspace'
            Valuename = 'AllowSuggestedAppsInWindowsInkWorkspace'
            Type      = 'REG_DWORD'
            Data      = @{
                Enable  = 1
                Disable = 0
            }
        }
    }
}
