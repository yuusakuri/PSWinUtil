function Get-WUAndroidPlatformVersion {
    <#
    .SYNOPSIS
    Gets the latest stable Android SDK Platform version from a package listing.

    .DESCRIPTION
    Parses Android CLI package listings and returns the greatest stable Android SDK Platform API level.

    .PARAMETER InputObject
    Specifies the lines returned by android sdk list.

    .EXAMPLE
    Get-WUAndroidPlatformVersion -InputObject 'platforms/android-36  2.0.0  Android SDK Platform 36'

    Returns 36.

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
        [regex]::Matches($text, '(?m)^\s*platforms/android-(\d+)\s+') |
            ForEach-Object { [int]$_.Groups[1].Value } |
            Sort-Object -Descending -Unique |
            Select-Object -First 1
    )
    if ($version.Count -eq 0) {
        throw 'No stable Android SDK Platform package was found.'
    }

    [string]$version[0]
}
