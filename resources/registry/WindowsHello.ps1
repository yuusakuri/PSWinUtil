@{
  WindowsHello                        = @{
    LocalMachine = @{
      KeyName   = 'HKEY_LOCAL_MACHINE\SOFTWARE\Policies\Microsoft\PassportForWork\PINComplexity'
      ValueName = '(Default)'
      Type      = 'REG_DWORD'
      Data      = @{
        Enable  = 1
        Disable = 0
      }
    }
  }
  AllowSignInOptions                  = @{
    LocalMachine = @{
      KeyName   = 'HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\PolicyManager\default\Settings\AllowSignInOptions'
      ValueName = 'value'
      Type      = 'REG_DWORD'
      Data      = @{
        Enable  = 1
        Disable = 0
      }
    }
  }
  Biometrics                          = @{
    LocalMachine = @{
      KeyName   = 'HKEY_LOCAL_MACHINE\SOFTWARE\Policies\Microsoft\Biometrics'
      ValueName = 'Enabled'
      Type      = 'REG_DWORD'
      Data      = @{
        Enable  = 1 #remove
        Disable = 0
      }
    }
  }
  AllowDomainPINLogon                 = @{
    LocalMachine = @{
      KeyName   = 'HKEY_LOCAL_MACHINE\Software\Policies\Microsoft\Windows\System'
      ValueName = 'AllowDomainPINLogon'
      Type      = 'REG_DWORD'
      Data      = @{
        Enable  = 1
        Disable = 0
      }
    }
  }
  AllowDomainUsersBiometrics          = @{
    LocalMachine = @{
      KeyName   = 'HKEY_LOCAL_MACHINE\SOFTWARE\Policies\Microsoft\Biometrics\Credential Provider'
      ValueName = 'Domain Accounts'
      Type      = 'REG_DWORD'
      Data      = @{
        Enable  = 1
        Disable = 0
      }
    }
  }
  UseWindowsHelloForBusiness          = @{
    LocalMachine = @{
      KeyName   = 'HKEY_LOCAL_MACHINE\SOFTWARE\Policies\Microsoft\PassportForWork'
      ValueName = 'Enabled'
      Type      = 'REG_DWORD'
      Data      = @{
        Enable  = 1
        Disable = 0
      }
    }
  }
  WindowsHelloProvisioningAfterSignIn = @{
    LocalMachine = @{
      KeyName   = 'HKEY_LOCAL_MACHINE\SOFTWARE\Policies\Microsoft\PassportForWork'
      ValueName = 'DisablePostLogonProvisioning'
      Type      = 'REG_DWORD'
      Data      = @{
        Enable  = 0
        Disable = 1
      }
    }
  }
}
