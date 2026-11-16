function Enable-WUUsbPartition {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [int]$DiskNumber
    )

    $typesWithoutDriveLetter = @(
        'Reserved'
        'System'
        'Recovery'
        'Extended'
    )
    $partitions = Get-Partition -ErrorAction Stop |
        Where-Object { $_.DiskNumber -eq $DiskNumber }

    foreach ($partition in $partitions) {
        $partitionSelector = @{
            DiskNumber = $DiskNumber
            PartitionNumber = $partition.PartitionNumber
            ErrorAction = 'Stop'
        }
        if ($partition.IsOffline) {
            Set-Partition @partitionSelector -IsOffline $false
        }

        $driveLetter = ([string]$partition.DriveLetter).Trim([char]0, ' ')
        $acceptsDriveLetter = -not $partition.IsHidden -and $partition.Type -notin $typesWithoutDriveLetter
        if ($driveLetter.Length -eq 0 -and $acceptsDriveLetter) {
            Add-PartitionAccessPath @partitionSelector -AssignDriveLetter
        }
    }
}
