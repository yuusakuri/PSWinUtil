function ConvertTo-WUPSSingleQuotedStringLiteral {
    <#
    .SYNOPSIS
    Converts strings to single-quoted PowerShell string literals.

    .DESCRIPTION
    Encloses each input string in single quotation marks and escapes embedded single quotation marks by doubling them. Empty strings are returned as empty single-quoted string literals.

    .PARAMETER InputObject
    Specifies one or more strings to convert.

    .EXAMPLE
    ConvertTo-WUPSSingleQuotedStringLiteral -InputObject "It's ready"

    Returns 'It''s ready'.

    .EXAMPLE
    'first value', '', "third'value" | ConvertTo-WUPSSingleQuotedStringLiteral

    Converts each pipeline value to a complete single-quoted PowerShell string literal.

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
            ValueFromPipeline = $true,
            ValueFromPipelineByPropertyName = $true
        )]
        [AllowEmptyString()]
        [ValidateNotNull()]
        [string[]]$InputObject
    )

    process {
        foreach ($currentInput in $InputObject) {
            "'{0}'" -f $currentInput.Replace("'", "''")
        }
    }
}
