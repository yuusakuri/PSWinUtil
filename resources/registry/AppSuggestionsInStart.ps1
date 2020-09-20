@{
  AppSuggestionsInStart = @{
    User = @{
      KeyName   = 'HKEY_CURRENT_USER\SOFTWARE\Microsoft\Windows\CurrentVersion\ContentDeliveryManager'
      ValueName = 'SystemPaneSuggestionsEnabled'
      Type      = 'REG_DWORD'
      Data      = @{
        Enable  = 1
        Disable = 0
      }
    }
  }
}
