@{
    WindowsSmartScreen         = @{
        LocalMachine = @{
            KeyName   = 'HKEY_LOCAL_MACHINE\SOFTWARE\Policies\Microsoft\Windows\System'
            ValueName = 'EnableSmartScreen'
            Type      = 'REG_DWORD'
            Data      = @{
                Enable  = 1
                Disable = 0
            }
        }
    }
    WindowsDefenderSmartScreen = @{
        LocalMachine = @{
            KeyName   = 'HKLM\SOFTWARE\Policies\Microsoft\MicrosoftEdge\PhishingFilter'
            ValueName = 'EnabledV9'
            Type      = 'REG_DWORD'
            Data      = @{
                Enable  = 1
                Disable = 0
            }
        }
    }
}
