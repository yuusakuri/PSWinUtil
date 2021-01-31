@{
    # Blocking of downloaded files
    SaveZoneInformation = @{
        CurrentUser = @{
            Keyname   = 'HKEY_CURRENT_USER\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\Attachments'
            Valuename = 'SaveZoneInformation'
            Type      = 'REG_DWORD'
            Data      = @{
                Enable  = 2
                Disable = 1
            }
        }
    }
}
