function Close-WUOutFile {
    [CmdletBinding()]
    param(
        [Parameter()]
        [AllowNull()]
        [object]$FormatPipeline,

        [Parameter()]
        [AllowNull()]
        [System.IO.TextWriter]$StreamWriter,

        [Parameter()]
        [AllowNull()]
        [System.IO.Stream]$FileStream,

        [Parameter(Mandatory = $true)]
        [string]$FullPath,

        [Parameter()]
        [switch]$RestoreReadOnly
    )

    try {
        if ($null -ne $FormatPipeline) {
            $FormatPipeline.Dispose()
        }
    } finally {
        try {
            if ($null -ne $StreamWriter) {
                $StreamWriter.Dispose()
            }
        } finally {
            if ($null -ne $FileStream) {
                $FileStream.Dispose()
            }
            if ($RestoreReadOnly) {
                $attributes = [System.IO.File]::GetAttributes($FullPath)
                [System.IO.File]::SetAttributes($FullPath, ($attributes -bor [System.IO.FileAttributes]::ReadOnly))
            }
        }
    }
}
