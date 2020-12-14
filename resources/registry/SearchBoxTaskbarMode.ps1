@{
    SearchBoxTaskbarMode = @{
        CurrentUser = @{
            KeyName   = 'HKCU\Software\Microsoft\Windows\CurrentVersion\Search'
            ValueName = 'SearchboxTaskbarMode'
            Type      = 'REG_DWORD'
            Data      = @{
                Box  = 2
                Icon = 1
                None = 0
            }
        }
    }
}
