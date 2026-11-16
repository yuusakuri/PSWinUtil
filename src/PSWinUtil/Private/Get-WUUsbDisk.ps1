function Get-WUUsbDisk {
    [CmdletBinding()]
    param(
        [int]$DiskNumber
    )

    if ($PSBoundParameters.ContainsKey('DiskNumber')) {
        $disk = Get-Disk -Number $DiskNumber -ErrorAction Stop
        if ($disk.BusType -ne 'USB') {
            throw [System.InvalidOperationException]::new(
                "Disk $DiskNumber is not a USB disk. Its bus type is '$($disk.BusType)'."
            )
        }
    } else {
        $usbDisks = @(Get-Disk -ErrorAction Stop | Where-Object { $_.BusType -eq 'USB' })
        if ($usbDisks.Count -eq 0) {
            throw [System.InvalidOperationException]::new('No USB disk is connected.')
        }

        if ($usbDisks.Count -gt 1) {
            $usbDiskNumbers = ($usbDisks | Select-Object -ExpandProperty Number) -join ', '
            throw [System.InvalidOperationException]::new(
                "More than one USB disk is connected (disk $usbDiskNumbers). Specify DiskNumber."
            )
        }

        $disk = $usbDisks | Select-Object -First 1
    }

    if ($disk.IsSystem -or $disk.IsBoot) {
        throw [System.InvalidOperationException]::new("Disk $($disk.Number) contains the running Windows installation.")
    }

    $disk
}
