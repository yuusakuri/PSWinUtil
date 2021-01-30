@{
    EdgeFirstRunExperience = @{
        LocalMachine = @{
            KeyName   = 'HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Edge'
            ValueName = 'HideFirstRunExperience'
            Type      = 'REG_DWORD'
            Data      = @{
                Enable  = 0
                Disable = 1
            }
        }
    }
}
