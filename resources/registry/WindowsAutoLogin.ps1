@{
  Enable   = @{
    Machine = @{
      KeyName   = 'HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon'
      ValueName = 'AutoAdminLogon'
      Type      = 'REG_DWORD'
      Data      = @{
        Enable  = 1
        Disable = 0
      }
    }
  }
  Username = @{
    Machine = @{
      KeyName   = 'HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon'
      ValueName = 'DefaultUserName'
      Type      = 'REG_SZ'
      Data      = ''
    }
  }
  Password = @{
    Machine = @{
      KeyName   = 'HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon'
      ValueName = 'DefaultPassword'
      Type      = 'REG_SZ'
      Data      = ''
    }
  }
}
