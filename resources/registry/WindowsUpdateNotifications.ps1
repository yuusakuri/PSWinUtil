@{
    WindowsUpdateNotifications = @{
        LocalMachine = @{
            KeyName   = 'HKEY_LOCAL_MACHINE\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate'
            ValueName = 'SetAutoRestartNotificationDisable'
            Type      = 'REG_DWORD'
            Data      = @{
                Enable  = 0
                Disable = 1
            }
        }
    }
}
