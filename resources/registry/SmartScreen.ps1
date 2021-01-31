@{
    WindowsSmartScreen         = @{
        LocalMachine = @{
            Keyname   = 'HKEY_LOCAL_MACHINE\SOFTWARE\Policies\Microsoft\Windows\System'
            Valuename = 'EnableSmartScreen'
            Type      = 'REG_DWORD'
            Data      = @{
                Enable  = 1
                Disable = 0
            }
        }
    }
    WindowsDefenderSmartScreen = @{
        LocalMachine = @{
            Keyname   = 'HKLM\SOFTWARE\Policies\Microsoft\MicrosoftEdge\PhishingFilter'
            Valuename = 'EnabledV9'
            Type      = 'REG_DWORD'
            Data      = @{
                Enable  = 1
                Disable = 0
            }
        }
    }
}
