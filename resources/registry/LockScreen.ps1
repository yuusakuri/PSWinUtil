@{
  LockScreen = @{
    Machine = @{
      KeyName   = 'HKEY_LOCAL_MACHINE\SOFTWARE\Policies\Microsoft\Windows\Personalization'
      ValueName = 'NoLockScreen'
      Type      = 'REG_DWORD'
      Data      = @{
        Enable  = 0
        Disable = 1
      }
    }
  }
}
