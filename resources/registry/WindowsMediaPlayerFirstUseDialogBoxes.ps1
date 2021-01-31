@{
    WindowsMediaPlayerFirstUseDialogBoxes = @{
        LocalMachine = @{
            Keyname   = 'HKEY_LOCAL_MACHINE\Software\Policies\Microsoft\WindowsMediaPlayer'
            Valuename = 'GroupPrivacyAcceptance'
            Type      = 'REG_DWORD'
            Data      = @{
                Enable  = 1
                Disable = 0
            }
        }
    }
}
