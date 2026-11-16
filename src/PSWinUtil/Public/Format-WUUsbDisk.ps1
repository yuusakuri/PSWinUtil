function Format-WUUsbDisk {
    <#
    .SYNOPSIS
    Erases a USB disk and formats it as one volume.

    .DESCRIPTION
    Brings the USB disk online, clears its read-only attribute, removes every partition, creates one partition, formats it, and assigns a drive letter. All data on the disk is lost. The command asks for confirmation unless -Confirm:$false is specified. A disk that is not connected through USB, or that contains the running Windows installation, is rejected. Windows formats FAT32 volumes up to 32 GB, so a FAT32 partition on a larger disk uses the first 32000 MB. Run this command in an elevated session.

    .PARAMETER DiskNumber
    Specifies the number of the USB disk to format, as shown by Get-Disk. When omitted, the only connected USB disk is formatted. The command fails when no USB disk or more than one USB disk is connected.

    .PARAMETER FileSystem
    Specifies the file system of the new volume. The default is FAT32.

    .PARAMETER PartitionStyle
    Specifies the partition style of the disk. The default is MBR.

    .PARAMETER DriveLetter
    Specifies the drive letter of the new volume. When omitted, Windows assigns an available letter.

    .PARAMETER FileSystemLabel
    Specifies the label of the new volume. FAT32 accepts up to 11 characters.

    .PARAMETER PassThru
    Returns the formatted volume.

    .EXAMPLE
    Format-WUUsbDisk

    Erases the only connected USB disk and formats it as FAT32 after confirmation.

    .EXAMPLE
    Format-WUUsbDisk -DiskNumber 1 -FileSystem NTFS -FileSystemLabel 'DATA' -Confirm:$false

    Erases USB disk 1 and formats it as NTFS without asking for confirmation.

    .INPUTS
    None

    .OUTPUTS
    Microsoft.Management.Infrastructure.CimInstance#ROOT/Microsoft/Windows/Storage/MSFT_Volume
    #>
    [CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'High')]
    [OutputType('Microsoft.Management.Infrastructure.CimInstance#ROOT/Microsoft/Windows/Storage/MSFT_Volume')]
    param(
        [Parameter(Position = 0)]
        [ValidateRange(0, [int]::MaxValue)]
        [int]$DiskNumber,

        [ValidateSet('FAT32', 'exFAT', 'NTFS')]
        [string]$FileSystem = 'FAT32',

        [ValidateSet('MBR', 'GPT')]
        [string]$PartitionStyle = 'MBR',

        [ValidatePattern('^[A-Za-z]$')]
        [string]$DriveLetter,

        [ValidateLength(1, 32)]
        [string]$FileSystemLabel,

        [switch]$PassThru
    )

    $diskParameters = @{}
    if ($PSBoundParameters.ContainsKey('DiskNumber')) {
        $diskParameters.DiskNumber = $DiskNumber
    }

    $disk = Get-WUUsbDisk @diskParameters
    $targetDiskNumber = $disk.Number
    $target = "Disk $targetDiskNumber ($($disk.FriendlyName))"
    if (-not $PSCmdlet.ShouldProcess($target, "Erase all data and format as $FileSystem")) {
        return
    }

    $volumeParameters = @{
        DiskNumber = $targetDiskNumber
        FileSystem = $FileSystem
        PartitionStyle = $PartitionStyle
    }
    if ($PSBoundParameters.ContainsKey('DriveLetter')) {
        $volumeParameters.DriveLetter = $DriveLetter
    }

    if ($PSBoundParameters.ContainsKey('FileSystemLabel')) {
        $volumeParameters.FileSystemLabel = $FileSystemLabel
    }

    $assignedDriveLetter = Initialize-WUUsbDiskVolume @volumeParameters
    if ($PassThru) {
        Get-Volume -DriveLetter ([char]$assignedDriveLetter) -ErrorAction Stop
    }
}
