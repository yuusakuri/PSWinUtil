@{
  ScalingBehavior = @{
    User    = @{
      KeyName   = 'HKCU\Software\Microsoft\Windows NT\CurrentVersion\AppCompatFlags\Layers'
      ValueName = ''
      Type      = 'REG_SZ'
      Data      = @{
        Application    = '~ HIGHDPIAWARE'
        System         = '~ DPIUNAWARE'
        SystemEnhanced = '~ GDIDPISCALING DPIUNAWARE'
      }
    }
    Machine = @{
      KeyName   = 'HKLM\Software\Microsoft\Windows NT\CurrentVersion\AppCompatFlags\Layers'
      ValueName = ''
      Type      = 'REG_SZ'
      Data      = @{
        Application    = '~ HIGHDPIAWARE'
        System         = '~ DPIUNAWARE'
        SystemEnhanced = '~ GDIDPISCALING DPIUNAWARE'
      }
    }
  }
}
