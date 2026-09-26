function Wait-WUBrowserDownload {
    [CmdletBinding()]
    [OutputType([string])]
    param(
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$TargetPath,

        [Parameter(Mandatory = $true)]
        [ValidateRange(1, 86400)]
        [int]$TimeoutSeconds
    )

    $partialPaths = @("$TargetPath.crdownload", "$TargetPath.part")
    $observedPaths = @($partialPaths) + $TargetPath
    $highestObservedFileLengths = @{}
    $stopwatch = [Diagnostics.Stopwatch]::StartNew()
    while ($true) {
        $currentFileLengths = @{}
        foreach ($path in $observedPaths) {
            $file = Get-Item -LiteralPath $path -ErrorAction SilentlyContinue
            if ($null -ne $file -and -not $file.PSIsContainer) {
                $currentFileLengths[$path] = [long]$file.Length
            }
        }

        $progressObserved = $false
        foreach ($path in $currentFileLengths.Keys) {
            if (
                $currentFileLengths[$path] -gt 0 -and
                (
                    -not $highestObservedFileLengths.ContainsKey($path) -or
                    $currentFileLengths[$path] -gt $highestObservedFileLengths[$path]
                )
            ) {
                $progressObserved = $true
                break
            }
        }
        if ($progressObserved) {
            $stopwatch.Restart()
        }
        foreach ($path in $currentFileLengths.Keys) {
            if (
                -not $highestObservedFileLengths.ContainsKey($path) -or
                $currentFileLengths[$path] -gt $highestObservedFileLengths[$path]
            ) {
                $highestObservedFileLengths[$path] = $currentFileLengths[$path]
            }
        }

        $partialFileExists = @(
            $partialPaths | Where-Object { Test-Path -LiteralPath $_ }
        ).Count -gt 0
        if (
            -not $partialFileExists -and
            (Test-Path -LiteralPath $TargetPath -PathType Leaf)
        ) {
            return [IO.Path]::GetFullPath($TargetPath)
        }

        if ($stopwatch.Elapsed.TotalSeconds -ge $TimeoutSeconds) {
            break
        }
        Start-Sleep -Milliseconds 200
    }

    throw "The browser download made no progress for $TimeoutSeconds seconds and did not complete: $TargetPath"
}
