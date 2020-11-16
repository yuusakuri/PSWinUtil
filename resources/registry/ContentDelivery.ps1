@{
  PreInstalledAppsEnabled     = @{
    CurrentUser = @{
      KeyName   = 'HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\ContentDeliveryManager'
      ValueName = 'PreInstalledAppsEnabled'
      Type      = 'REG_DWORD'
      Data      = @{
        Enable  = 1
        Disable = 0
      }
    }
  }
  PreInstalledAppsEverEnabled = @{
    CurrentUser = @{
      KeyName   = 'HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\ContentDeliveryManager'
      ValueName = 'PreInstalledAppsEverEnabled'
      Type      = 'REG_DWORD'
      Data      = @{
        Enable  = 1
        Disable = 0
      }
    }
  }
  OEMPreInstalledAppsEnabled  = @{
    CurrentUser = @{
      KeyName   = 'HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\ContentDeliveryManager'
      ValueName = 'OEMPreInstalledAppsEnabled'
      Type      = 'REG_DWORD'
      Data      = @{
        Enable  = 1
        Disable = 0
      }
    }
  }
  SilentInstalledAppsEnabled  = @{
    CurrentUser = @{
      KeyName   = 'HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\ContentDeliveryManager'
      ValueName = 'SilentInstalledAppsEnabled'
      Type      = 'REG_DWORD'
      Data      = @{
        Enable  = 1
        Disable = 0
      }
    }
  }
  ContentDeliveryAllowed      = @{
    CurrentUser = @{
      KeyName   = 'HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\ContentDeliveryManager'
      ValueName = 'ContentDeliveryAllowed'
      Type      = 'REG_DWORD'
      Data      = @{
        Enable  = 1
        Disable = 0
      }
    }
  }
  SubscribedContentEnabled    = @{
    CurrentUser = @{
      KeyName   = 'HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\ContentDeliveryManager'
      ValueName = 'SubscribedContentEnabled'
      Type      = 'REG_DWORD'
      Data      = @{
        Enable  = 1
        Disable = 0
      }
    }
  }
}
