function New-WUBootableUsbDisk {
    <#
    .SYNOPSIS
    Writes an ISO image to a USB disk to create UEFI boot media.

    .DESCRIPTION
    Mounts the ISO image, erases the USB disk, creates one FAT32 partition on an MBR disk, and copies the ISO content to it. All data on the disk is lost. The command asks for confirmation unless -Confirm:$false is specified. The ISO image is checked before the disk is erased: it must contain a UEFI boot loader in EFI\BOOT and fit on the partition. A sources\install.wim file larger than 4 GB is split into install.swm files; any other file larger than 4 GB is rejected. The volume label is taken from the first 11 characters of the ISO label. The media boots on UEFI firmware only. Legacy BIOS boot and sector-by-sector image writing are not supported. A disk that is not connected through USB, or that contains the running Windows installation, is rejected. Run this command in an elevated session.

    .PARAMETER ImagePath
    Specifies the path of the ISO image. Wildcard characters are not interpreted.

    .PARAMETER DiskNumber
    Specifies the number of the USB disk to write, as shown by Get-Disk. When omitted, the only connected USB disk is written. The command fails when no USB disk or more than one USB disk is connected.

    .PARAMETER PassThru
    Returns the volume that contains the copied ISO content.

    .EXAMPLE
    New-WUBootableUsbDisk -ImagePath '.\ubuntu-24.04-live-server-amd64.iso'

    Erases the only connected USB disk and writes the ISO image to it after confirmation.

    .EXAMPLE
    New-WUBootableUsbDisk -ImagePath '.\ubuntu-24.04-live-server-amd64.iso' -DiskNumber 1 -Confirm:$false

    Erases USB disk 1 and writes the ISO image to it without asking for confirmation.

    .INPUTS
    None

    .OUTPUTS
    Microsoft.Management.Infrastructure.CimInstance#ROOT/Microsoft/Windows/Storage/MSFT_Volume
    #>
    [CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'High')]
    [OutputType('Microsoft.Management.Infrastructure.CimInstance#ROOT/Microsoft/Windows/Storage/MSFT_Volume')]
    param(
        [Parameter(Mandatory = $true, Position = 0)]
        [ValidateNotNullOrEmpty()]
        [string]$ImagePath,

        [Parameter(Position = 1)]
        [ValidateRange(0, [int]::MaxValue)]
        [int]$DiskNumber,

        [switch]$PassThru
    )

    $fat32MaximumPartitionSize = 32000MB
    $fat32MaximumLabelLength = 11

    $image = Get-Item -LiteralPath $ImagePath -ErrorAction Stop
    if ($image.PSIsContainer -or $image.Extension -ne '.iso') {
        throw [System.ArgumentException]::new("The path is not an ISO image file: $ImagePath", 'ImagePath')
    }

    $imageFullPath = $image.FullName
    $diskParameters = @{}
    if ($PSBoundParameters.ContainsKey('DiskNumber')) {
        $diskParameters.DiskNumber = $DiskNumber
    }

    $disk = Get-WUUsbDisk @diskParameters
    $targetDiskNumber = $disk.Number
    $target = "Disk $targetDiskNumber ($($disk.FriendlyName))"
    if (-not $PSCmdlet.ShouldProcess($target, "Erase all data and write $imageFullPath")) {
        return
    }

    Write-Verbose -Message "Mounting $imageFullPath."
    Mount-DiskImage -ImagePath $imageFullPath -StorageType ISO -Access ReadOnly -ErrorAction Stop | Out-Null
    try {
        $isoVolume = Get-WUIsoVolume -ImagePath $imageFullPath
        $capacity = [math]::Min([long]$disk.Size, [long]$fat32MaximumPartitionSize)
        Assert-WUIsoContent -SourceRoot $isoVolume.Root -Capacity $capacity

        $volumeParameters = @{
            DiskNumber = $targetDiskNumber
            FileSystem = 'FAT32'
            PartitionStyle = 'MBR'
        }
        $label = ($isoVolume.FileSystemLabel.ToUpperInvariant() -replace '[^A-Z0-9_ -]', '_')
        if ($label.Length -gt $fat32MaximumLabelLength) {
            $label = $label.Substring(0, $fat32MaximumLabelLength)
        }

        $label = $label.Trim()
        if ($label.Length -gt 0) {
            $volumeParameters.FileSystemLabel = $label
        }

        $assignedDriveLetter = Initialize-WUUsbDiskVolume @volumeParameters
        Copy-WUIsoContent -SourceRoot $isoVolume.Root -DestinationRoot "${assignedDriveLetter}:\"
    } finally {
        Dismount-DiskImage -ImagePath $imageFullPath -ErrorAction Stop | Out-Null
    }

    if ($PassThru) {
        Get-Volume -DriveLetter ([char]$assignedDriveLetter) -ErrorAction Stop
    }
}
