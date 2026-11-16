function Repair-WUUsbDisk {
    <#
    .SYNOPSIS
    Makes offline or read-only USB disks accessible again.

    .DESCRIPTION
    Brings each USB disk and its partitions online, clears the read-only attribute of the disk, and assigns a drive letter to each data partition that has none. Existing data is kept. When DiskNumber is omitted, every connected USB disk is repaired. A disk that is not connected through USB is rejected. Run this command in an elevated session. Use Format-WUUsbDisk when the partition table or file system is damaged.

    .PARAMETER DiskNumber
    Specifies the numbers of the USB disks to repair, as shown by Get-Disk.

    .EXAMPLE
    Repair-WUUsbDisk

    Repairs every connected USB disk.

    .EXAMPLE
    Repair-WUUsbDisk -DiskNumber 1

    Brings USB disk 1 online, clears its read-only attribute, and assigns missing drive letters.

    .INPUTS
    System.Int32

    .OUTPUTS
    None
    #>
    [CmdletBinding(SupportsShouldProcess = $true)]
    param(
        [Parameter(Position = 0, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true)]
        [Alias('Number')]
        [ValidateRange(0, [int]::MaxValue)]
        [int[]]$DiskNumber
    )

    process {
        $targetDiskNumbers = $DiskNumber
        if (-not $PSBoundParameters.ContainsKey('DiskNumber')) {
            $targetDiskNumbers = Get-Disk -ErrorAction Stop |
                Where-Object { $_.BusType -eq 'USB' } |
                Select-Object -ExpandProperty Number
        }

        if ($null -eq $targetDiskNumbers) {
            Write-Error -Message 'No USB disk is connected.' -Category ObjectNotFound
            return
        }

        foreach ($currentDiskNumber in $targetDiskNumbers) {
            try {
                $disk = Get-WUUsbDisk -DiskNumber $currentDiskNumber
                $target = "Disk $currentDiskNumber ($($disk.FriendlyName))"
                if ($PSCmdlet.ShouldProcess($target, 'Bring online, clear read-only, and assign drive letters')) {
                    Enable-WUUsbDisk -Disk $disk
                    Enable-WUUsbPartition -DiskNumber $currentDiskNumber
                }
            } catch {
                Write-Error -ErrorRecord $_
            }
        }
    }
}
