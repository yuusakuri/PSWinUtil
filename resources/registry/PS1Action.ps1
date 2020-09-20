@{
  PS1Action = @{
    Machine = @{
      KeyName   = 'HKEY_CLASSES_ROOT\Microsoft.PowerShellScript.1\Shell'
      ValueName = '(Default)'
      Type      = 'REG_DWORD'
      Data      = @{
        Run  = 0
        Edit = 'Open'
      }
    }
  }
}
