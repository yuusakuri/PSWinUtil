@{
    Enable1  = @{
        LocalMachine = @{
            Keyname   = 'HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon'
            Valuename = 'AutoAdminLogon'
            Type      = 'REG_DWORD'
            Data      = @{
                Enable  = 1
                Disable = 0
            }
        }
    }
    Enable2  = @{
        LocalMachine = @{
            Keyname   = 'HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows NT\CurrentVersion\PasswordLess\Device'
            Valuename = 'DevicePasswordLessBuildVersion'
            Type      = 'REG_DWORD'
            Data      = @{
                Enable  = 0
                Disable = 2
            }
        }
    }
    Username = @{
        LocalMachine = @{
            Keyname   = 'HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon'
            Valuename = 'DefaultUserName'
            Type      = 'REG_SZ'
            Data      = ''
        }
    }
    Password = @{
        LocalMachine = @{
            Keyname   = 'HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon'
            Valuename = 'DefaultPassword'
            Type      = 'REG_SZ'
            Data      = ''
        }
    }
}
