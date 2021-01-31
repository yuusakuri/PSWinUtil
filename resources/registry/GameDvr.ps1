@{
    GameDvr = @{
        LocalMachine = @{
            KeyName   = 'HKLM\Software\Policies\Microsoft\Windows\GameDVR'
            Valuename = 'AllowGameDVR'
            Type      = 'REG_DWORD'
            Data      = @{
                Enable  = 1
                Disable = 0
            }
        }
    }
}
