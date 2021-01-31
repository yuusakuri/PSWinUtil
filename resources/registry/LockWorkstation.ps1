@{
    LockWorkstation = @{
        CurrentUser = @{
            Keyname   = 'HKEY_CURRENT_USER\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System'
            Valuename = 'DisableLockWorkstation'
            Type      = 'REG_DWORD'
            Data      = @{
                Enable  = 0
                Disable = 1
            }
        }
    }
}
