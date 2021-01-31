@{
    ConsentPromptBehaviorAdmin = @{
        LocalMachine = @{
            KeyName   = 'HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System'
            Valuename = 'ConsentPromptBehaviorAdmin'
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
            Valuename = 'PromptOnSecureDesktop'
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
            Valuename = 'EnableLUA'
            Type      = 'REG_DWORD'
            Data      = @{
                Enable  = 1
                Disable = 0
            }
        }
    }
}
