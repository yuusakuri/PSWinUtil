function Get-WUHttpDownloadResponseLayout {
    [CmdletBinding()]
    [OutputType([pscustomobject])]
    param(
        [Parameter(Mandatory = $true)]
        [System.Net.Http.HttpResponseMessage]$Response,

        [Parameter(Mandatory = $true)]
        [long]$SavedLength
    )

    $fileMode = [System.IO.FileMode]::Create
    $expectedLength = $Response.Content.Headers.ContentLength
    $progressStartLength = $SavedLength

    if ($Response.StatusCode -eq [System.Net.HttpStatusCode]::PartialContent) {
        $contentRange = $Response.Content.Headers.ContentRange
        if ($null -eq $contentRange -or $contentRange.From -ne $SavedLength) {
            throw "The server returned an invalid Content-Range for offset $SavedLength."
        }
        if ($SavedLength -gt 0) {
            $fileMode = [System.IO.FileMode]::Append
        }
        if ($contentRange.HasLength) {
            $expectedLength = $contentRange.Length
        } elseif ($null -ne $expectedLength) {
            $expectedLength += $SavedLength
        }
    } elseif ($SavedLength -gt 0) {
        $progressStartLength = 0L
    }

    [pscustomobject]@{
        FileMode = $fileMode
        ExpectedLength = $expectedLength
        ProgressStartLength = $progressStartLength
    }
}
