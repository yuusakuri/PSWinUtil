@{
    EdgeFirstRunExperience = @{
        LocalMachine = @{
            KeyName   = 'HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Edge'
            Valuename = 'HideFirstRunExperience'
            Type      = 'REG_DWORD'
            Data      = @{
                Enable  = 0
                Disable = 1
            }
        }
    }
}
