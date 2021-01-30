@{
    WindowsMediaPlayerFirstUseDialogBoxes = @{
        LocalMachine = @{
            KeyName   = 'HKEY_LOCAL_MACHINE\Software\Policies\Microsoft\WindowsMediaPlayer'
            ValueName = 'GroupPrivacyAcceptance'
            Type      = 'REG_DWORD'
            Data      = @{
                Enable  = 1
                Disable = 0
            }
        }
    }
}
