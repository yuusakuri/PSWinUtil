@{
  WindowsUpdateAutoRestart = @{
    Machine = @{
      KeyName   = 'HKLM\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate\AU'
      ValueName = 'NoAutoRebootWithLoggedOnUsers'
      Type      = 'REG_DWORD'
      Data      = @{
        Enable  = 0
        Disable = 1
      }
    }
  }
}
