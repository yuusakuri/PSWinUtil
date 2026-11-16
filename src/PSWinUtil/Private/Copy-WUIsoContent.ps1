function Copy-WUIsoContent {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$SourceRoot,

        [Parameter(Mandatory = $true)]
        [string]$DestinationRoot,

        [long]$MaximumFileLength = 4GB - 1
    )

    $splitImageFileSizeMegabyte = 3800
    $sourceRootPath = $SourceRoot.TrimEnd('\') + '\'

    $directories = Get-ChildItem -LiteralPath $SourceRoot -Recurse -Directory -Force -ErrorAction Stop
    foreach ($directory in $directories) {
        $relativePath = $directory.FullName.Substring($sourceRootPath.Length)
        [System.IO.Directory]::CreateDirectory((Join-Path -Path $DestinationRoot -ChildPath $relativePath)) | Out-Null
    }

    $files = @(Get-ChildItem -LiteralPath $SourceRoot -Recurse -File -Force -ErrorAction Stop)
    Write-Verbose -Message "Copying $($files.Count) files from $SourceRoot to $DestinationRoot."

    foreach ($file in $files) {
        $relativePath = $file.FullName.Substring($sourceRootPath.Length)
        $destinationPath = Join-Path -Path $DestinationRoot -ChildPath $relativePath
        if ($file.Length -gt $MaximumFileLength) {
            Write-Verbose -Message "Splitting $relativePath because it is larger than $MaximumFileLength bytes."
            $splitParameters = @{
                ImagePath = $file.FullName
                SplitImagePath = [System.IO.Path]::ChangeExtension($destinationPath, '.swm')
                FileSize = $splitImageFileSizeMegabyte
                CheckIntegrity = $true
                ErrorAction = 'Stop'
            }
            Split-WindowsImage @splitParameters | Out-Null
        } else {
            Copy-Item -LiteralPath $file.FullName -Destination $destinationPath -Force -ErrorAction Stop
        }
    }
}
