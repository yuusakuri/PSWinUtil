@{
    WindowsSecurityNonCriticalNotifications = @{
        LocalMachine = @{
            Keyname   = 'HKEY_LOCAL_MACHINE\SOFTWARE\Policies\Microsoft\Windows Defender Security Center\Notifications'
            Valuename = 'DisableEnhancedNotifications'
            Type      = 'REG_DWORD'
            Data      = @{
                Enable  = 0
                Disable = 1
            }
        }
    }
}
