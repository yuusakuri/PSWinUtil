function Join-WUPathEnvironmentVariable {
    <#
    .SYNOPSIS
    Joins PATH environment variable items.

    .DESCRIPTION
    Joins zero or more PATH items with semicolons without changing their text or order.

    .PARAMETER Path
    Specifies the PATH items to join.

    .EXAMPLE
    Join-WUPathEnvironmentVariable -Path 'C:\Tools', 'C:\Apps'

    Returns C:\Tools;C:\Apps.

    .INPUTS
    None

    .OUTPUTS
    System.String
    #>
    [CmdletBinding()]
    [OutputType([string])]
    param(
        [Parameter(Mandatory = $true)]
        [AllowEmptyCollection()]
        [string[]]$Path
    )

    $Path -join ';'
}
