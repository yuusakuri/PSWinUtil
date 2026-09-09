function Close-WUOutFile {
    [CmdletBinding()]
    param(
        [Parameter()]
        [AllowNull()]
        [object]$FormatPipeline,

        [Parameter()]
        [AllowNull()]
        [System.IO.TextWriter]$StreamWriter,

        [Parameter(Mandatory = $true)]
        [string]$FullPath,

        [Parameter()]
        [AllowNull()]
        [object]$OriginalAttributes
    )

    if ($null -ne $FormatPipeline) {
        $FormatPipeline.Dispose()
    }
    if ($null -ne $StreamWriter) {
        $StreamWriter.Dispose()
    }
    if ($null -ne $OriginalAttributes) {
        [System.IO.File]::SetAttributes($FullPath, $OriginalAttributes)
    }
}
