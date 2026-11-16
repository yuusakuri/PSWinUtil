function Initialize-WUUsbDiskVolume {
    [CmdletBinding()]
    [OutputType([string])]
    param(
        [Parameter(Mandatory = $true)]
        [int]$DiskNumber,

        [Parameter(Mandatory = $true)]
        [ValidateSet('FAT32', 'exFAT', 'NTFS')]
        [string]$FileSystem,

        [Parameter(Mandatory = $true)]
        [ValidateSet('MBR', 'GPT')]
        [string]$PartitionStyle,

        [string]$DriveLetter,

        [string]$FileSystemLabel
    )

    # Windows does not format FAT32 volumes larger than 32 GB.
    $fat32MaximumPartitionSize = 32000MB

    $disk = Get-Disk -Number $DiskNumber -ErrorAction Stop
    Enable-WUUsbDisk -Disk $disk
    if ($disk.PartitionStyle -ne 'RAW') {
        Write-Verbose -Message "Erasing disk $DiskNumber."
        Clear-Disk -Number $DiskNumber -RemoveData -RemoveOEM -Confirm:$false -ErrorAction Stop
    }

    # Removable media can stay initialized after Clear-Disk, so read the style again.
    $disk = Get-Disk -Number $DiskNumber -ErrorAction Stop
    if ($disk.PartitionStyle -eq 'RAW') {
        Initialize-Disk -Number $DiskNumber -PartitionStyle $PartitionStyle -ErrorAction Stop
    } elseif ($disk.PartitionStyle -ne $PartitionStyle) {
        Set-Disk -Number $DiskNumber -PartitionStyle $PartitionStyle -ErrorAction Stop
    }

    $partitionParameters = @{
        DiskNumber = $DiskNumber
        ErrorAction = 'Stop'
    }
    if ($FileSystem -eq 'FAT32' -and $disk.Size -gt $fat32MaximumPartitionSize) {
        $partitionParameters.Size = $fat32MaximumPartitionSize
    } else {
        $partitionParameters.UseMaximumSize = $true
    }

    if ($PartitionStyle -eq 'MBR' -and $FileSystem -eq 'FAT32') {
        $partitionParameters.MbrType = 'FAT32'
    } elseif ($PartitionStyle -eq 'MBR') {
        $partitionParameters.MbrType = 'IFS'
    }

    if ($DriveLetter) {
        $partitionParameters.DriveLetter = [char]$DriveLetter.ToUpperInvariant()
    } else {
        $partitionParameters.AssignDriveLetter = $true
    }

    Write-Verbose -Message "Creating a $PartitionStyle partition on disk $DiskNumber."
    $partition = New-Partition @partitionParameters
    $assignedDriveLetter = ([string]$partition.DriveLetter).Trim([char]0, ' ')
    if ($assignedDriveLetter.Length -eq 0) {
        throw [System.InvalidOperationException]::new("Windows did not assign a drive letter to disk $DiskNumber.")
    }

    $formatParameters = @{
        DriveLetter = [char]$assignedDriveLetter
        FileSystem = $FileSystem
        Confirm = $false
        ErrorAction = 'Stop'
    }
    if ($FileSystemLabel) {
        $formatParameters.NewFileSystemLabel = $FileSystemLabel
    }

    Write-Verbose -Message "Formatting drive ${assignedDriveLetter}: as $FileSystem."
    Format-Volume @formatParameters | Out-Null

    $assignedDriveLetter
}
