function Invoke-WUHttpFileDownload {
    <#
    .SYNOPSIS
    Downloads a file over HTTP.

    .DESCRIPTION
    Reuses a module HttpClient, reads the response as a stream, and writes it to a new file. An incomplete file is removed when the request or file copy fails. The caller approves the file change before invoking this function.

    .PARAMETER Uri
    Specifies an absolute HTTP or HTTPS URI.

    .PARAMETER Path
    Specifies a new file system path for the response body.

    .PARAMETER TimeoutSeconds
    Specifies the maximum number of seconds for the request and file transfer.

    .EXAMPLE
    Invoke-WUHttpFileDownload -Uri 'https://example.com/package.zip' -Path 'C:\Downloads\package.zip' -TimeoutSeconds 300

    Downloads package.zip without opening a browser.

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
        [string]$Path,

        [Parameter(Mandatory = $true)]
        [ValidateRange(1, 86400)]
        [int]$TimeoutSeconds
    )

    if (-not $Uri.IsAbsoluteUri -or $Uri.Scheme -notin @('http', 'https')) {
        throw 'Uri must be an absolute HTTP or HTTPS URI.'
    }
    $fullPath = ConvertTo-WUFullPath -Path $Path
    $parentPath = Split-Path -Path $fullPath -Parent
    Assert-WUPathProperty -LiteralPath $parentPath -Container
    if (Test-Path -LiteralPath $fullPath) {
        throw "The download target already exists: $fullPath"
    }

    Add-Type -AssemblyName 'System.Net.Http' -ErrorAction Stop
    $clientVariable = Get-Variable -Name 'WUHttpClient' -Scope Script -ErrorAction Ignore
    if ($null -eq $clientVariable -or $null -eq $clientVariable.Value) {
        $script:WUHttpClient = [System.Net.Http.HttpClient]::new()
        $script:WUHttpClient.Timeout = [System.Threading.Timeout]::InfiniteTimeSpan
    }

    $cancellationSource = [System.Threading.CancellationTokenSource]::new()
    $request = [System.Net.Http.HttpRequestMessage]::new(
        [System.Net.Http.HttpMethod]::Get,
        $Uri
    )
    $response = $null
    $responseStream = $null
    $fileStream = $null
    $completed = $false
    try {
        $cancellationSource.CancelAfter([TimeSpan]::FromSeconds($TimeoutSeconds))
        $response = $script:WUHttpClient.SendAsync(
            $request,
            [System.Net.Http.HttpCompletionOption]::ResponseHeadersRead,
            $cancellationSource.Token
        ).GetAwaiter().GetResult()
        $null = $response.EnsureSuccessStatusCode()
        $responseStream = $response.Content.ReadAsStreamAsync().GetAwaiter().GetResult()
        $fileStream = [System.IO.FileStream]::new(
            $fullPath,
            [System.IO.FileMode]::CreateNew,
            [System.IO.FileAccess]::Write,
            [System.IO.FileShare]::None,
            81920,
            [System.IO.FileOptions]::SequentialScan
        )
        $null = $responseStream.CopyToAsync(
            $fileStream,
            81920,
            $cancellationSource.Token
        ).GetAwaiter().GetResult()
        $fileStream.Flush()
        $completed = $true
        $fullPath
    } finally {
        if ($null -ne $fileStream) {
            $fileStream.Dispose()
        }
        if ($null -ne $responseStream) {
            $responseStream.Dispose()
        }
        if ($null -ne $response) {
            $response.Dispose()
        }
        $request.Dispose()
        $cancellationSource.Dispose()
        if (-not $completed -and (Test-Path -LiteralPath $fullPath -PathType Leaf)) {
            Remove-Item -LiteralPath $fullPath -Force -ErrorAction SilentlyContinue
        }
    }
}
