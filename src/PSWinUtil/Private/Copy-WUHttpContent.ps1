function Copy-WUHttpContent {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [System.IO.Stream]$InputStream,

        [Parameter(Mandatory = $true)]
        [System.IO.Stream]$OutputStream
    )

    $InputStream.CopyTo($OutputStream)
}
