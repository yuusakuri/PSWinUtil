﻿@{
    WebsiteAccessToLanguageList = @{
        # WEBサイトが言語リストにアクセス
        CurrentUser = @{
            Keyname   = 'HKEY_CURRENT_USER\Control Panel\International\User Profile'
            Valuename = 'HttpAcceptLanguageOptOut'
            Type      = 'REG_DWORD'
            Data      = @{
                Enable  = 1
                Disable = 0
            }
        }
    }
}
