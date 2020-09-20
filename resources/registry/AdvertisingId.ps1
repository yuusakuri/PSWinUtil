@{
  AdvertisingId = @{
    # 広告識別子
    User    = @{
      KeyName   = 'HKEY_CURRENT_USER\SOFTWARE\Microsoft\Windows\CurrentVersion\AdvertisingInfo'
      ValueName = 'Enabled'
      Type      = 'REG_DWORD'
      Data      = @{
        Enable  = 1
        Disable = 0
      }
    }
    Machine = @{
      # https://getadmx.com/?Category=Windows_10_2016&Policy=Microsoft.Policies.UserProfiles::DisableAdvertisingId
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
