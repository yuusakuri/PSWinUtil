@{
    ScalingBehavior = @{
        CurrentUser  = @{
            Keyname   = 'HKCU\Software\Microsoft\Windows NT\CurrentVersion\AppCompatFlags\Layers'
            Valuename = ''
            Type      = 'REG_SZ'
            Data      = @{
                Application    = '~ HIGHDPIAWARE'
                System         = '~ DPIUNAWARE'
                SystemEnhanced = '~ GDIDPISCALING DPIUNAWARE'
            }
        }
        LocalMachine = @{
            Keyname   = 'HKLM\Software\Microsoft\Windows NT\CurrentVersion\AppCompatFlags\Layers'
            Valuename = ''
            Type      = 'REG_SZ'
            Data      = @{
                Application    = '~ HIGHDPIAWARE'
                System         = '~ DPIUNAWARE'
                SystemEnhanced = '~ GDIDPISCALING DPIUNAWARE'
            }
        }
    }
}
