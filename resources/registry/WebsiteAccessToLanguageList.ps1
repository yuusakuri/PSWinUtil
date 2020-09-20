@{
  WebsiteAccessToLanguageList = @{
    # WEBサイトが言語リストにアクセス
    User = @{
      KeyName   = 'HKEY_CURRENT_USER\Control Panel\International\User Profile'
      ValueName = 'HttpAdcceptLanguageOptOut'
      Type      = 'REG_DWORD'
      Data      = @{
        Enable  = 1
        Disable = 0
      }
    }
  }
}
