@{
    WindowsUpdateAutoRestart = @{
        LocalMachine = @{
            KeyName   = 'HKLM\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate\AU'
            Valuename = 'NoAutoRebootWithLoggedOnUsers'
            Type      = 'REG_DWORD'
            Data      = @{
                Enable  = 0
                Disable = 1
            }
        }
    }
}
