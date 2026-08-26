function Invoke-WUDefaultBrowserDownloadInternal {
    <#
    .SYNOPSIS
    Downloads a file with the default browser.

    .DESCRIPTION
    Removes approved existing and partial target files, opens a URI with the default browser, and waits until the exact target file exists without browser partial files or an exclusive file lock.

    .PARAMETER Uri
    Specifies the absolute HTTP or HTTPS URI opened by the default browser.

    .PARAMETER FileName
    Specifies the target leaf file name.

    .PARAMETER DownloadDirectory
    Specifies an existing download directory.

    .PARAMETER TimeoutSeconds
    Specifies the maximum number of seconds to wait.

    .PARAMETER Force
    Allows an existing target file to be removed before the browser starts.

    .EXAMPLE
    Invoke-WUDefaultBrowserDownloadInternal -Uri 'https://example.com/package.zip' -FileName 'package.zip' -DownloadDirectory 'C:\Downloads' -TimeoutSeconds 300

    Opens the package URI and waits for C:\Downloads\package.zip.

    .INPUTS
    None

    .OUTPUTS
    System.String
    #>
    [CmdletBinding()]
    [OutputType([string])]
    param(
        [Parameter(Mandatory = $true)]
        [ValidateNotNull()]
        [uri]$Uri,

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$FileName,

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$DownloadDirectory,

        [Parameter(Mandatory = $true)]
        [ValidateRange(1, 86400)]
        [int]$TimeoutSeconds,

        [Parameter()]
        [switch]$Force
    )

    if (-not $Uri.IsAbsoluteUri -or $Uri.Scheme -notin @('http', 'https')) {
        throw 'Uri must be an absolute HTTP or HTTPS URI.'
    }
    if (
        [IO.Path]::GetFileName($FileName) -cne $FileName -or
        $FileName.IndexOfAny([IO.Path]::GetInvalidFileNameChars()) -ge 0
    ) {
        throw "FileName must be a valid leaf file name: $FileName"
    }

    $fullDownloadDirectory = Resolve-WUExistingFileSystemPath `
        -LiteralPath $DownloadDirectory `
        -Container
    $targetPath = Join-Path -Path $fullDownloadDirectory -ChildPath $FileName
    if ((Test-Path -LiteralPath $targetPath -PathType Leaf) -and -not $Force) {
        throw "The target file already exists. Use Force to replace it: $targetPath"
    }

    if (Test-Path -LiteralPath $targetPath -PathType Leaf) {
        Remove-Item -LiteralPath $targetPath -Force -ErrorAction Stop
    }
    $partialPaths = @("$targetPath.crdownload", "$targetPath.part")
    foreach ($partialPath in $partialPaths) {
        if (Test-Path -LiteralPath $partialPath) {
            Remove-Item -LiteralPath $partialPath -Force -ErrorAction Stop
        }
    }

    $null = Start-Process -FilePath $Uri.AbsoluteUri -ErrorAction Stop
    $stopwatch = [Diagnostics.Stopwatch]::StartNew()
    try {
        while ($stopwatch.Elapsed.TotalSeconds -lt $TimeoutSeconds) {
            $partialFileExists = @(
                $partialPaths | Where-Object { Test-Path -LiteralPath $_ }
            ).Count -gt 0
            if ((Test-Path -LiteralPath $targetPath -PathType Leaf) -and -not $partialFileExists) {
                $stream = $null
                try {
                    $stream = [IO.File]::Open(
                        $targetPath,
                        [IO.FileMode]::Open,
                        [IO.FileAccess]::Read,
                        [IO.FileShare]::None
                    )
                    [IO.Path]::GetFullPath($targetPath)
                    return
                } catch [IO.IOException] {
                    $null = $_
                } catch [UnauthorizedAccessException] {
                    $null = $_
                } finally {
                    if ($null -ne $stream) {
                        $stream.Dispose()
                    }
                }
            }

            Start-Sleep -Milliseconds 200
        }
    } finally {
        $stopwatch.Stop()
    }

    throw "The browser download did not complete within $TimeoutSeconds seconds: $targetPath"
}
