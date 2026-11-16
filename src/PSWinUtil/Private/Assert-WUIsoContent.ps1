function Assert-WUIsoContent {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$SourceRoot,

        [Parameter(Mandatory = $true)]
        [long]$Capacity,

        [long]$MaximumFileLength = 4GB - 1
    )

    $bootDirectory = Join-Path -Path $SourceRoot -ChildPath 'EFI\BOOT'
    $bootLoaders = @()
    if (Test-Path -LiteralPath $bootDirectory -PathType Container) {
        $bootLoaders = @(Get-ChildItem -LiteralPath $bootDirectory -Filter 'boot*.efi' -File -ErrorAction Stop)
    }

    if ($bootLoaders.Count -eq 0) {
        throw [System.InvalidOperationException]::new(
            'The ISO image has no UEFI boot loader in EFI\BOOT. Only UEFI-bootable ISO images are supported.'
        )
    }

    $sourceRootPath = $SourceRoot.TrimEnd('\') + '\'
    $files = @(Get-ChildItem -LiteralPath $SourceRoot -Recurse -File -Force -ErrorAction Stop)
    $oversizedFile = $files |
        Where-Object {
            $_.Length -gt $MaximumFileLength -and
            $_.FullName.Substring($sourceRootPath.Length) -ne 'sources\install.wim'
        } |
        Select-Object -First 1
    if ($null -ne $oversizedFile) {
        throw [System.InvalidOperationException]::new(
            "The ISO image contains a file that FAT32 cannot store: $($oversizedFile.FullName)"
        )
    }

    $totalLength = $files |
        Measure-Object -Property Length -Sum |
        Select-Object -ExpandProperty Sum
    if ($totalLength -gt $Capacity) {
        throw [System.InvalidOperationException]::new(
            "The ISO content needs $totalLength bytes, but the USB disk provides $Capacity bytes."
        )
    }
}
