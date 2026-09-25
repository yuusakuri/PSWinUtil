function Invoke-WUHttpFileDownload {
    <#
    .SYNOPSIS
    Downloads a file over HTTP with automatic resume.

    .DESCRIPTION
    Downloads an HTTP or HTTPS response to a file. A new download starts with a normal GET request. If a request or stream transfer fails after writing data, the command requests the remaining bytes from the saved file length. A server that ignores a range request and returns 200 OK causes the file to be rewritten from the beginning. A failed attempt that writes no additional data ends the operation and preserves the partial file.

    .PARAMETER Uri
    Specifies an absolute HTTP or HTTPS URI.

    .PARAMETER Path
    Specifies the destination file path. An existing file is treated as partial content and used as the resume position.

    .EXAMPLE
    Invoke-WUHttpFileDownload -Uri 'https://example.com/package.zip' -Path 'C:\Downloads\package.zip'

    Downloads package.zip and resumes from saved content when a transfer fails after making progress.

    .INPUTS
    None

    .OUTPUTS
    System.String
    #>
    [CmdletBinding(SupportsShouldProcess = $true)]
    [OutputType([string])]
    param(
        [Parameter(Mandatory = $true)]
        [ValidateNotNull()]
        [uri]$Uri,

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$Path
    )

    if (-not $Uri.IsAbsoluteUri -or $Uri.Scheme -notin @('http', 'https')) {
        throw 'Uri must be an absolute HTTP or HTTPS URI.'
    }

    $fullPath = ConvertTo-WUFullPath -Path $Path
    $parentPath = Split-Path -Path $fullPath -Parent
    Assert-WUPathProperty -LiteralPath $parentPath -Container
    if (Test-Path -LiteralPath $fullPath -PathType Container) {
        throw "The download target must be a file path: $fullPath"
    }
    if (-not $PSCmdlet.ShouldProcess($fullPath, "Download from $($Uri.AbsoluteUri)")) {
        return
    }

    Add-Type -AssemblyName 'System.Net.Http' -ErrorAction Stop
    $clientVariable = Get-Variable -Name 'WUHttpClient' -Scope Script -ErrorAction Ignore
    if ($null -eq $clientVariable -or $null -eq $clientVariable.Value) {
        $script:WUHttpClient = [System.Net.Http.HttpClient]::new()
        $script:WUHttpClient.Timeout = [System.Threading.Timeout]::InfiniteTimeSpan
    }

    while ($true) {
        $savedLength = 0L
        if (Test-Path -LiteralPath $fullPath -PathType Leaf) {
            $savedLength = [System.IO.FileInfo]::new($fullPath).Length
        }

        $request = [System.Net.Http.HttpRequestMessage]::new(
            [System.Net.Http.HttpMethod]::Get,
            $Uri
        )
        if ($savedLength -gt 0) {
            $request.Headers.Range = [System.Net.Http.Headers.RangeHeaderValue]::new(
                $savedLength,
                $null
            )
        }

        $response = $null
        $responseStream = $null
        $fileStream = $null
        $attemptError = $null
        $completed = $false
        $progressStartLength = $savedLength
        try {
            $response = $script:WUHttpClient.SendAsync(
                $request,
                [System.Net.Http.HttpCompletionOption]::ResponseHeadersRead
            ).GetAwaiter().GetResult()
            $response.EnsureSuccessStatusCode() | Out-Null

            $fileMode = [System.IO.FileMode]::Create
            $expectedLength = $response.Content.Headers.ContentLength
            if ($response.StatusCode -eq [System.Net.HttpStatusCode]::PartialContent) {
                $contentRange = $response.Content.Headers.ContentRange
                if ($null -eq $contentRange -or $contentRange.From -ne $savedLength) {
                    throw "The server returned an invalid Content-Range for offset $savedLength."
                }
                if ($savedLength -gt 0) {
                    $fileMode = [System.IO.FileMode]::Append
                }
                if ($contentRange.HasLength) {
                    $expectedLength = $contentRange.Length
                } elseif ($null -ne $expectedLength) {
                    $expectedLength += $savedLength
                }
            } elseif ($savedLength -gt 0) {
                $progressStartLength = 0L
            }

            $responseStream = $response.Content.ReadAsStreamAsync().GetAwaiter().GetResult()
            $fileStream = [System.IO.FileStream]::new(
                $fullPath,
                $fileMode,
                [System.IO.FileAccess]::Write,
                [System.IO.FileShare]::None,
                81920,
                [System.IO.FileOptions]::SequentialScan
            )
            Copy-WUHttpContent -InputStream $responseStream -OutputStream $fileStream
            $fileStream.Flush()

            if ($null -ne $expectedLength -and $fileStream.Length -ne $expectedLength) {
                throw "The HTTP response ended after $($fileStream.Length) of $expectedLength bytes."
            }
            $completed = $true
        } catch {
            $attemptError = $_
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
        }

        if ($completed) {
            return $fullPath
        }

        $savedAfterAttempt = 0L
        if (Test-Path -LiteralPath $fullPath -PathType Leaf) {
            $savedAfterAttempt = [System.IO.FileInfo]::new($fullPath).Length
        }
        if ($savedAfterAttempt -gt $progressStartLength) {
            continue
        }
        throw $attemptError
    }
}
