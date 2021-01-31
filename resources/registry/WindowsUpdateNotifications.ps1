@{
    SetAutoRestartNotificationDisable = @{
        LocalMachine = @{
            KeyName   = 'HKEY_LOCAL_MACHINE\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate'
            Valuename = 'SetAutoRestartNotificationDisable'
            Type      = 'REG_DWORD'
            Data      = @{
                Enable  = 0
                Disable = 1
            }
        }
    }
    SetUpdateNotificationLevel        = @{
        LocalMachine = @{
            KeyName   = 'HKEY_LOCAL_MACHINE\Software\Policies\Microsoft\Windows\WindowsUpdate'
            Valuename = 'SetUpdateNotificationLevel'
            Type      = 'REG_DWORD'
            Data      = @{
                Enable  = 1
                Disable = 1
            }
        }
    }
    UpdateNotificationLevel           = @{
        LocalMachine = @{
            KeyName   = 'HKEY_LOCAL_MACHINE\Software\Policies\Microsoft\Windows\WindowsUpdate'
            Valuename = 'UpdateNotificationLevel'
            Type      = 'REG_DWORD'
            Data      = @{
                Enable  = 0
                Disable = 2
            }
        }
    }
}
