@{
    SystemUsesDarkTheme = @{
        CurrentUser = @{
            KeyName   = 'HKCU\Software\Microsoft\Windows\CurrentVersion\Themes\Personalize'
            Valuename = 'SystemUsesLightTheme'
            Type      = 'REG_DWORD'
            Data      = @{
                Enable  = 0
                Disable = 1
            }
        }
    }
    AppsUseDarkTheme    = @{
        CurrentUser = @{
            KeyName   = 'HKCU\Software\Microsoft\Windows\CurrentVersion\Themes\Personalize'
            Valuename = 'AppsUseLightTheme'
            Type      = 'REG_DWORD'
            Data      = @{
                Enable  = 0
                Disable = 1
            }
        }
    }
}
