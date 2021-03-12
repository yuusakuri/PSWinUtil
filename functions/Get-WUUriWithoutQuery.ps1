<#
    .SYNOPSIS
    Get url without query string.

    .DESCRIPTION
    Get url without query string.

    .OUTPUTS
    Uri
    Returns the Uri without the query string.

    .EXAMPLE
    PS C:\>Get-WUUriWithoutQuery -Uri 'https://www.google.com/search?q=powershell'

    This example returns the Uri of `https://www.google.com/search`, excluding the query string, from the value of the parameter Uri.
#>

[CmdletBinding()]
param (
    # Specify a Uri to remove the query.
    [Parameter(Mandatory,
        Position = 0,
        ValueFromPipeline,
        ValueFromPipelineByPropertyName)]
    [ValidateNotNullOrEmpty()]
    [uri[]]
    $Uri
)

foreach ($aUri in $Uri) {
    [uri]($aUri -replace '\?.+')
}
