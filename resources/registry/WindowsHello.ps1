@{
  WindowsHello = @{
    Machine = @{
      KeyName   = 'HKEY_LOCAL_MACHINE\SOFTWARE\Policies\Microsoft\PassportForWork'
      ValueName = '(Default)'
      Type      = 'REG_DWORD'
      Data      = @{
        Enable  = 1
        Disable = 0
      }
    }
  }
}
