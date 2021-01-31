@{
    AppLaunchTracking = @{
        CurrentUser = @{
            # 追跡アプリ
            KeyName   = 'HKEY_CURRENT_USER\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Advanced'
            Valuename = 'Start_TrackProgs'
            Type      = 'REG_DWORD'
            Data      = @{
                Enable  = 1
                Disable = 0
            }
        }
    }
}
