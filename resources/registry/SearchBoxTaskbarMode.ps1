@{
    SearchBoxTaskbarMode = @{
        CurrentUser = @{
            Keyname   = 'HKCU\Software\Microsoft\Windows\CurrentVersion\Search'
            Valuename = 'SearchboxTaskbarMode'
            Type      = 'REG_DWORD'
            Data      = @{
                Box  = 2
                Icon = 1
                None = 0
            }
        }
    }
}
