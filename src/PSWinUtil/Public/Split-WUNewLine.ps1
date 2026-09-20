function Split-WUNewLine {
    <#
    .SYNOPSIS
    Splits text into lines at LF or CRLF newlines.

    .DESCRIPTION
    Accepts text from the pipeline or InputObject and writes one string for each line. Empty lines, including an empty final line, are preserved.

    .PARAMETER InputObject
    Specifies the text to split into lines.

    .EXAMPLE
    $result.StandardOutput | Split-WUNewLine

    Splits captured command output into lines.

    .INPUTS
    System.String

    .OUTPUTS
    System.String
    #>
    [CmdletBinding()]
    [OutputType([string])]
    param(
        [Parameter(Mandatory = $true, Position = 0, ValueFromPipeline = $true)]
        [AllowEmptyString()]
        [string]$InputObject
    )

    process {
        $InputObject -split '\r?\n'
    }
}
