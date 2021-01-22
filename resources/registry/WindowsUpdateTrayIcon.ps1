@{
    WindowsUpdateTrayIcon = @{
        LocalMachine = @{
            KeyName   = 'HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\WindowsUpdate\UX\Settings'
            ValueName = 'TrayIconVisibility'
            Type      = 'REG_DWORD'
            Data      = @{
                Enable  = 1
                Disable = 0
            }
        }
    }
}
