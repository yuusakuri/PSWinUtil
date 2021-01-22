﻿@{
    BingSearchEnabled    = @{
        CurrentUser = @{
            KeyName   = 'HKEY_CURRENT_USER\SOFTWARE\Microsoft\Windows\CurrentVersion\Search'
            ValueName = 'BingSearchEnabled'
            Type      = 'REG_DWORD'
            Data      = @{
                Enable  = 1
                Disable = 0
            }
        }
    }
    WebSearchInStartMenu = @{
        # Windows 10 v2004 or later
        CurrentUser = @{
            KeyName   = 'HKEY_CURRENT_USER\SOFTWARE\Policies\Microsoft\Windows'
            ValueName = 'DisableSearchBoxSuggestions'
            Type      = 'REG_DWORD'
            Data      = @{
                Enable  = 0
                Disable = 1
            }
        }
    }
}