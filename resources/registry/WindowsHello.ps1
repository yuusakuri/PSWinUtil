@{
    WindowsHello                        = @{
        LocalMachine = @{
            Keyname   = 'HKEY_LOCAL_MACHINE\SOFTWARE\Policies\Microsoft\PassportForWork\PINComplexity'
            Valuename = '(Default)'
            Type      = 'REG_DWORD'
            Data      = @{
                Enable  = 1
                Disable = 0
            }
        }
    }
    AllowSignInOptions                  = @{
        LocalMachine = @{
            Keyname   = 'HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\PolicyManager\default\Settings\AllowSignInOptions'
            Valuename = 'value'
            Type      = 'REG_DWORD'
            Data      = @{
                Enable  = 1
                Disable = 0
            }
        }
    }
    Biometrics                          = @{
        LocalMachine = @{
            Keyname   = 'HKEY_LOCAL_MACHINE\SOFTWARE\Policies\Microsoft\Biometrics'
            Valuename = 'Enabled'
            Type      = 'REG_DWORD'
            Data      = @{
                Enable  = 1 #remove
                Disable = 0
            }
        }
    }
    AllowDomainPINLogon                 = @{
        LocalMachine = @{
            Keyname   = 'HKEY_LOCAL_MACHINE\Software\Policies\Microsoft\Windows\System'
            Valuename = 'AllowDomainPINLogon'
            Type      = 'REG_DWORD'
            Data      = @{
                Enable  = 1
                Disable = 0
            }
        }
    }
    AllowDomainUsersBiometrics          = @{
        LocalMachine = @{
            Keyname   = 'HKEY_LOCAL_MACHINE\SOFTWARE\Policies\Microsoft\Biometrics\Credential Provider'
            Valuename = 'Domain Accounts'
            Type      = 'REG_DWORD'
            Data      = @{
                Enable  = 1
                Disable = 0
            }
        }
    }
    UseWindowsHelloForBusiness          = @{
        LocalMachine = @{
            Keyname   = 'HKEY_LOCAL_MACHINE\SOFTWARE\Policies\Microsoft\PassportForWork'
            Valuename = 'Enabled'
            Type      = 'REG_DWORD'
            Data      = @{
                Enable  = 1
                Disable = 0
            }
        }
    }
    WindowsHelloProvisioningAfterSignIn = @{
        LocalMachine = @{
            Keyname   = 'HKEY_LOCAL_MACHINE\SOFTWARE\Policies\Microsoft\PassportForWork'
            Valuename = 'DisablePostLogonProvisioning'
            Type      = 'REG_DWORD'
            Data      = @{
                Enable  = 0
                Disable = 1
            }
        }
    }
}
