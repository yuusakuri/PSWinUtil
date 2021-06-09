@{
    LongPaths = @{
        LocalMachine = @{
            Keyname   = 'HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\FileSystem'
            Valuename = 'LongPathsEnabled'
            Type      = 'REG_DWORD'
            Data      = @{
                Enable  = 1
                Disable = 0
            }
        }
    }
}
