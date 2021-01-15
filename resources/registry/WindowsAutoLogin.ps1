@{
    Enable1  = @{
        LocalMachine = @{
            KeyName   = 'HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon'
            ValueName = 'AutoAdminLogon'
            Type      = 'REG_DWORD'
            Data      = @{
                Enable  = 1
                Disable = 0
            }
        }
    }
    Enable2  = @{
        LocalMachine = @{
            KeyName   = 'HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows NT\CurrentVersion\PasswordLess\Device'
            ValueName = 'DevicePasswordLessBuildVersion'
            Type      = 'REG_DWORD'
            Data      = @{
                Enable  = 0
                Disable = 2
            }
        }
    }
    Username = @{
        LocalMachine = @{
            KeyName   = 'HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon'
            ValueName = 'DefaultUserName'
            Type      = 'REG_SZ'
            Data      = ''
        }
    }
    Password = @{
        LocalMachine = @{
            KeyName   = 'HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon'
            ValueName = 'DefaultPassword'
            Type      = 'REG_SZ'
            Data      = ''
        }
    }
}
