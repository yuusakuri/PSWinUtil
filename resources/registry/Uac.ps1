@{
    ConsentPromptBehaviorAdmin = @{
        LocalMachine = @{
            Keyname   = 'HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System'
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
            Keyname   = 'HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System'
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
            Keyname   = 'HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System'
            Valuename = 'EnableLUA'
            Type      = 'REG_DWORD'
            Data      = @{
                Enable  = 1
                Disable = 0
            }
        }
    }
}
