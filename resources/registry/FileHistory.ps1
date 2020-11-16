@{
  FileHistory = @{
    LocalMachine = @{
      KeyName   = 'HKLM\SOFTWARE\Policies\Microsoft\Windows\FileHistory'
      ValueName = 'Disabled'
      Type      = 'REG_DWORD'
      Data      = @{
        Enable  = 0
        Disable = 1
      }
    }
  }
}
