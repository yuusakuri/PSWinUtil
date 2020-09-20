@{
  SaveZoneInformation = @{
    Machine = @{
      KeyName   = 'HKEY_CURRENT_USER\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\Attachments'
      ValueName = 'SaveZoneInformation'
      Type      = 'REG_DWORD'
      Data      = @{
        Enable  = 2
        Disable = 1
      }
    }
  }
}
