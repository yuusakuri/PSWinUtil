function Invoke-WUDefaultBrowserDownload {
    <#
    .SYNOPSIS
    Downloads a file with the default browser.

    .DESCRIPTION
    Opens an HTTP or HTTPS URI with the Windows default browser and waits for the exact target file to become complete and unlocked in an existing download directory. This command is intended for environments where direct PowerShell HTTP traffic is unavailable.

    .PARAMETER Uri
    Specifies the absolute HTTP or HTTPS download URI.

    .PARAMETER FileName
    Specifies the target leaf file name. When omitted, the last segment of the URI path is used.

    .PARAMETER DownloadDirectory
    Specifies an existing browser download directory. The default value is the current user Downloads directory.

    .PARAMETER TimeoutSeconds
    Specifies the maximum number of seconds to wait. The default value is 300.

    .PARAMETER Force
    Allows an existing target file to be removed before the browser starts.

    .EXAMPLE
    Invoke-WUDefaultBrowserDownload -Uri 'https://example.com/package.zip'

    Opens the URI and waits for package.zip in the current user Downloads directory.

    .EXAMPLE
    Invoke-WUDefaultBrowserDownload -Uri 'https://example.com/current' -FileName 'package.zip' -DownloadDirectory 'C:\Downloads' -Force

    Replaces C:\Downloads\package.zip with the completed browser download.

    .INPUTS
    None

    .OUTPUTS
    System.String
    #>
    [CmdletBinding(SupportsShouldProcess = $true)]
    [OutputType([string])]
    param(
        [Parameter(Mandatory = $true, Position = 0)]
        [ValidateNotNull()]
        [uri]$Uri,

        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [string]$FileName,

        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [string]$DownloadDirectory = "$env:USERPROFILE\Downloads",

        [Parameter()]
        [ValidateRange(1, 86400)]
        [int]$TimeoutSeconds = 300,

        [Parameter()]
        [switch]$Force
    )

    if (-not $Uri.IsAbsoluteUri -or $Uri.Scheme -notin @('http', 'https')) {
        throw 'Uri must be an absolute HTTP or HTTPS URI.'
    }

    $resolvedFileName = $FileName
    if (-not $PSBoundParameters.ContainsKey('FileName')) {
        $escapedFileName = [IO.Path]::GetFileName($Uri.AbsolutePath)
        if ([string]::IsNullOrWhiteSpace($escapedFileName)) {
            throw 'FileName could not be determined from Uri.'
        }
        $resolvedFileName = [Uri]::UnescapeDataString($escapedFileName)
    }
    if (
        [IO.Path]::GetFileName($resolvedFileName) -cne $resolvedFileName -or
        $resolvedFileName.IndexOfAny([IO.Path]::GetInvalidFileNameChars()) -ge 0
    ) {
        throw "FileName must be a valid leaf file name: $resolvedFileName"
    }

    $fullDownloadDirectory = Resolve-WUPath -LiteralPath $DownloadDirectory -DenyMultiplePaths |
        ConvertTo-WUFullPath
    Assert-WUPathProperty -LiteralPath $fullDownloadDirectory -Container
    $targetPath = Join-Path -Path $fullDownloadDirectory -ChildPath $resolvedFileName
    if ((Test-Path -LiteralPath $targetPath -PathType Leaf) -and -not $Force) {
        throw "The target file already exists. Use Force to replace it: $targetPath"
    }

    if (-not $PSCmdlet.ShouldProcess($targetPath, "Download from $($Uri.AbsoluteUri) with default browser")) {
        return
    }

    $downloadParameters = @{
        Uri = $Uri
        FileName = $resolvedFileName
        DownloadDirectory = $fullDownloadDirectory
        TimeoutSeconds = $TimeoutSeconds
        Force = $Force
    }
    Invoke-WUDefaultBrowserDownloadInternal @downloadParameters
}
