@{
    ConsentPromptBehaviorAdmin = @{
        LocalMachine = @{
            KeyName   = 'HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System'
            ValueName = 'ConsentPromptBehaviorAdmin'
            Type      = 'REG_DWORD'
            Data      = @{
                Enable  = 2
                Disable = 0
            }
        }
    }
    PromptOnSecureDesktop      = @{
        LocalMachine = @{
            KeyName   = 'HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System'
            ValueName = 'PromptOnSecureDesktop'
            Type      = 'REG_DWORD'
            Data      = @{
                Enable  = 1
                Disable = 0
            }
        }
    }
    EnableLUA                  = @{
        LocalMachine = @{
            KeyName   = 'HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System'
            ValueName = 'EnableLUA'
            Type      = 'REG_DWORD'
            Data      = @{
                Enable  = 1
                Disable = 0
            }
        }
    }
}
