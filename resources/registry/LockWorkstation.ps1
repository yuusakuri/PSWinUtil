@{
    LockWorkstation = @{
        CurrentUser = @{
            KeyName   = 'HKEY_CURRENT_USER\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System'
            ValueName = 'DisableLockWorkstation'
            Type      = 'REG_DWORD'
            Data      = @{
                Enable  = 0
                Disable = 1
            }
        }
    }
}
