@{
    PS1Action = @{
        LocalMachine = @{
            KeyName   = 'HKEY_CLASSES_ROOT\Microsoft.PowerShellScript.1\Shell'
            Valuename = '(Default)'
            Type      = 'REG_SZ'
            Data      = @{
                Run     = "0"
                Edit    = 'Edit'
                Notepad = 'Open'
            }
        }
    }
}
