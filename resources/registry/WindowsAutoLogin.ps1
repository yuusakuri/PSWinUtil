@{
  Enable1  = @{
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
  Enable2  = @{
    Machine = @{
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
