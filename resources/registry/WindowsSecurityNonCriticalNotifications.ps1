@{
  WindowsSecurityNonCriticalNotifications = @{
    LocalMachine = @{
      KeyName   = 'HKEY_LOCAL_MACHINE\SOFTWARE\Policies\Microsoft\Windows Defender Security Center\Notifications'
      ValueName = 'DisableEnhancedNotifications'
      Type      = 'REG_DWORD'
      Data      = @{
        Enable  = 0
        Disable = 1
      }
    }
  }
}
