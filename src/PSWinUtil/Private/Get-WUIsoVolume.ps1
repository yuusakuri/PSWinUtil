function Get-WUIsoVolume {
    [CmdletBinding()]
    [OutputType([PSCustomObject])]
    param(
        [Parameter(Mandatory = $true)]
        [string]$ImagePath
    )

    $volume = Get-DiskImage -ImagePath $ImagePath -ErrorAction Stop |
        Get-Volume -ErrorAction Stop |
        Select-Object -First 1
    if ($null -eq $volume) {
        throw [System.InvalidOperationException]::new("The mounted ISO image has no volume: $ImagePath")
    }

    $driveLetter = ([string]$volume.DriveLetter).Trim([char]0, ' ')
    if ($driveLetter.Length -eq 0) {
        throw [System.InvalidOperationException]::new("Windows did not assign a drive letter to the ISO image: $ImagePath")
    }

    [PSCustomObject]@{
        Root = "${driveLetter}:\"
        FileSystemLabel = [string]$volume.FileSystemLabel
    }
}
