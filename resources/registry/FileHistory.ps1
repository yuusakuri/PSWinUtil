@{
    FileHistory = @{
        LocalMachine = @{
            Keyname   = 'HKLM\SOFTWARE\Policies\Microsoft\Windows\FileHistory'
            Valuename = 'Disabled'
            Type      = 'REG_DWORD'
            Data      = @{
                Enable  = 0
                Disable = 1
            }
        }
    }
}
