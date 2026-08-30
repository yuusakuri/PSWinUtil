function ConvertTo-WUPSStringLiteral {
    <#
    .SYNOPSIS
    Converts strings to PowerShell string literals.

    .DESCRIPTION
    Converts strings to PowerShell string literals using the specified quote type. The default quote type is Single.

    .PARAMETER InputObject
    Specifies one or more strings to convert.

    .PARAMETER QuoteType
    Specifies the quote type used for the string literal. Valid values are Single and Double.

    .EXAMPLE
    ConvertTo-WUPSStringLiteral -InputObject "don't"

    Returns a single-quoted PowerShell string literal.

    .EXAMPLE
    ConvertTo-WUPSStringLiteral -InputObject '$HOME' -QuoteType Double

    Returns a double-quoted PowerShell string literal while preserving the original string value.

    .EXAMPLE
    'first', '', 'third' | ConvertTo-WUPSStringLiteral

    Converts each string received from the pipeline.

    .INPUTS
    System.String

    .OUTPUTS
    System.String
    #>
    [CmdletBinding()]
    [OutputType([string])]
    param(
        [Parameter(
            Mandatory = $true,
            Position = 0,
            ValueFromPipeline = $true
        )]
        [AllowEmptyString()]
        [ValidateNotNull()]
        [string[]]$InputObject,

        [Parameter()]
        [ValidateSet('Single', 'Double')]
        [string]$QuoteType = 'Single'
    )

    process {
        foreach ($value in $InputObject) {
            switch ($QuoteType) {
                'Single' {
                    "'{0}'" -f $value.Replace("'", "''")
                }
                'Double' {
                    $escapedValue = $value.Replace('`', '``').Replace('"', '`"').Replace('$', '`$')
                    '"{0}"' -f $escapedValue
                }
            }
        }
    }
}
