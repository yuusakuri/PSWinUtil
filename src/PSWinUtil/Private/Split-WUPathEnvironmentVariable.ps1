function Split-WUPathEnvironmentVariable {
    <#
    .SYNOPSIS
    Splits a PATH environment variable value.

    .DESCRIPTION
    Splits a semicolon-separated PATH value, trims surrounding spaces, and removes empty items.

    .PARAMETER Value
    Specifies the PATH environment variable value to split.

    .EXAMPLE
    Split-WUPathEnvironmentVariable -Value 'C:\Tools; C:\Apps'

    Returns C:\Tools and C:\Apps as separate items.

    .INPUTS
    None

    .OUTPUTS
    System.String
    #>
    [CmdletBinding()]
    [OutputType([string])]
    param(
        [Parameter(Mandatory = $true)]
        [AllowNull()]
        [AllowEmptyString()]
        [string]$Value
    )

    if ([string]::IsNullOrWhiteSpace($Value)) {
        return
    }

    foreach ($pathItem in $Value.Split([char]';')) {
        $trimmedPath = $pathItem.Trim()
        if (-not [string]::IsNullOrWhiteSpace($trimmedPath)) {
            $trimmedPath
        }
    }
}
