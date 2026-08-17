function Convert-WUTextFileToUtf8Lf {
    <#
    .SYNOPSIS
    Converts a UTF-8 text file to UTF-8 without BOM and LF.

    .DESCRIPTION
    Detects common Unicode byte order marks, uses strict UTF-8 for a file without a byte order mark, and falls back to the current system encoding when UTF-8 decoding fails. It normalizes CRLF and CR to LF and writes UTF-8 without a byte order mark.

    .PARAMETER Path
    Specifies an existing file system path.

    .EXAMPLE
    Convert-WUTextFileToUtf8Lf -Path 'C:\Logs\output.txt'

    Converts the text file in place.

    .INPUTS
    None

    .OUTPUTS
    None
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$Path
    )

    [byte[]]$bytes = [System.IO.File]::ReadAllBytes($Path)
    $encoding = [System.Text.UTF8Encoding]::new($false, $true)
    if ($bytes.Length -ge 4 -and $bytes[0] -eq 0xFF -and $bytes[1] -eq 0xFE -and $bytes[2] -eq 0 -and $bytes[3] -eq 0) {
        $encoding = [System.Text.UTF32Encoding]::new($false, $true)
    } elseif ($bytes.Length -ge 4 -and $bytes[0] -eq 0 -and $bytes[1] -eq 0 -and $bytes[2] -eq 0xFE -and $bytes[3] -eq 0xFF) {
        $encoding = [System.Text.UTF32Encoding]::new($true, $true)
    } elseif ($bytes.Length -ge 2 -and $bytes[0] -eq 0xFF -and $bytes[1] -eq 0xFE) {
        $encoding = [System.Text.UnicodeEncoding]::new($false, $true)
    } elseif ($bytes.Length -ge 2 -and $bytes[0] -eq 0xFE -and $bytes[1] -eq 0xFF) {
        $encoding = [System.Text.UnicodeEncoding]::new($true, $true)
    }

    try {
        $content = $encoding.GetString($bytes)
    } catch [System.Text.DecoderFallbackException] {
        $content = [System.Text.Encoding]::Default.GetString($bytes)
    }
    if ($content.Length -gt 0 -and $content[0] -eq [char]0xFEFF) {
        $content = $content.Substring(1)
    }
    $content = $content.Replace("`r`n", "`n").Replace("`r", "`n")
    [System.IO.File]::WriteAllText($Path, $content, [System.Text.UTF8Encoding]::new($false))
}
