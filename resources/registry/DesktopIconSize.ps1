@{
    DesktopIconSize        = @{
        CurrentUser = @{
            KeyName   = 'HKCU\SOFTWARE\Microsoft\Windows\Shell\Bags\1\Desktop'
            Valuename = 'IconSize'
            Type      = 'REG_DWORD'
            Data      = @{
                ExtraLarge = 256
                Large      = 96
                Medium     = 48
                Small      = 32
            }
        }
    }
    DesktopMode            = @{
        CurrentUser = @{
            KeyName   = 'HKCU\SOFTWARE\Microsoft\Windows\Shell\Bags\1\Desktop'
            Valuename = 'Mode'
            Type      = 'REG_DWORD'
            Data      = @{
                ExtraLarge = 1
                Large      = 1
                Medium     = 1
                Small      = 1
            }
        }
    }
    DesktopLogicalViewMode = @{
        CurrentUser = @{
            KeyName   = 'HKCU\SOFTWARE\Microsoft\Windows\Shell\Bags\1\Desktop'
            Valuename = 'LogicalViewMode'
            Type      = 'REG_DWORD'
            Data      = @{
                ExtraLarge = 3
                Large      = 3
                Medium     = 3
                Small      = 3
            }
        }
    }
}
