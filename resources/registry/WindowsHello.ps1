@{
  WindowsHello               = @{
    Machine = @{
      KeyName   = 'HKEY_LOCAL_MACHINE\SOFTWARE\Policies\Microsoft\PassportForWork\PINComplexity'
      ValueName = '(Default)'
      Type      = 'REG_DWORD'
      Data      = @{
        Enable  = 1
        Disable = 0
      }
    }
  }
  AllowSignInOptions         = @{
    Machine = @{
      KeyName   = 'HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\PolicyManager\default\Settings\AllowSignInOptions'
      ValueName = 'value'
      Type      = 'REG_DWORD'
      Data      = @{
        Enable  = 1
        Disable = 0
      }
    }
  }
  Biometrics                 = @{
    Machine = @{
      KeyName   = 'HKEY_LOCAL_MACHINE\SOFTWARE\Policies\Microsoft\Biometrics'
      ValueName = 'Enabled'
      Type      = 'REG_DWORD'
      Data      = @{
        Enable  = 1 #remove
        Disable = 0
      }
    }
  }
  AllowDomainPINLogon        = @{
    Machine = @{
      KeyName   = 'HKEY_LOCAL_MACHINE\Software\Policies\Microsoft\Windows\System'
      ValueName = 'AllowDomainPINLogon'
      Type      = 'REG_DWORD'
      Data      = @{
        Enable  = 1
        Disable = 0
      }
    }
  }
  AllowDomainUsersBiometrics = @{
    Machine = @{
      KeyName   = 'HKEY_LOCAL_MACHINE\SOFTWARE\Policies\Microsoft\Biometrics\Credential Provider'
      ValueName = 'Domain Accounts'
      Type      = 'REG_DWORD'
      Data      = @{
        Enable  = 1
        Disable = 0
      }
    }
  }
}
