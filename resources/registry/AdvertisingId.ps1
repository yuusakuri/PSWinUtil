@{
    AdvertisingId = @{
        # 広告識別子
        CurrentUser  = @{
            KeyName   = 'HKEY_CURRENT_USER\SOFTWARE\Microsoft\Windows\CurrentVersion\AdvertisingInfo'
            ValueName = 'Enabled'
            Type      = 'REG_DWORD'
            Data      = @{
                Enable  = 1
                Disable = 0
            }
        }
        LocalMachine = @{
            KeyName   = 'HKEY_LOCAL_MACHINE\SOFTWARE\Policies\Microsoft\Windows\AdvertisingInfo'
            ValueName = 'DisabledByGroupPolicy'
            Type      = 'REG_DWORD'
            Data      = @{
                Enable  = 1
                Disable = 0
            }
        }
    }
}
