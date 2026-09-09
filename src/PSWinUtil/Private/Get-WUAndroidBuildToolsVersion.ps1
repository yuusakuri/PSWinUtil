function Get-WUAndroidBuildToolsVersion {
    <#
    .SYNOPSIS
    Gets the latest stable Android SDK Build Tools version from a package listing.

    .DESCRIPTION
    Parses Android CLI package listings and returns the greatest stable three-part Android SDK Build Tools version.

    .PARAMETER InputObject
    Specifies the lines returned by android sdk list.

    .EXAMPLE
    Get-WUAndroidBuildToolsVersion -InputObject 'build-tools/36.0.0  36.0.0  Android SDK Build-Tools 36'

    Returns 36.0.0.

    .INPUTS
    System.Object[]

    .OUTPUTS
    System.String
    #>
    [CmdletBinding()]
    [OutputType([string])]
    param(
        [Parameter(Mandatory = $true)]
        [AllowEmptyCollection()]
        [object[]]$InputObject
    )

    $text = $InputObject -join "`n"
    $version = @(
        [regex]::Matches($text, '(?m)^\s*build-tools/([0-9]+\.[0-9]+\.[0-9]+)\s+') |
            ForEach-Object { [version]$_.Groups[1].Value } |
            Sort-Object -Descending -Unique |
            Select-Object -First 1
    )
    if ($version.Count -eq 0) {
        throw 'No stable Android SDK Build Tools package was found.'
    }

    [string]$version[0]
}
