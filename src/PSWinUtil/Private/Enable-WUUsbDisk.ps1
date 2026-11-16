function Enable-WUUsbDisk {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [ValidateNotNull()]
        [object]$Disk
    )

    if ($Disk.IsOffline) {
        Set-Disk -Number $Disk.Number -IsOffline $false -ErrorAction Stop
    }

    if ($Disk.IsReadOnly) {
        Set-Disk -Number $Disk.Number -IsReadOnly $false -ErrorAction Stop
    }
}
