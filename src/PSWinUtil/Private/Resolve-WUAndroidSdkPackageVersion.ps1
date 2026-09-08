function Resolve-WUAndroidSdkPackageVersion {
    <#
    .SYNOPSIS
    Resolves the latest stable Android SDK package version.

    .DESCRIPTION
    Parses Android CLI package output and returns the greatest stable Android platform API level or three-part Build Tools version.

    .PARAMETER InputObject
    Specifies lines returned by android sdk list.

    .PARAMETER PackageType
    Specifies Platform or BuildTools.

    .EXAMPLE
    Resolve-WUAndroidSdkPackageVersion -InputObject 'platforms/android-36  2.0.0  Android SDK Platform 36' -PackageType Platform

    Returns 36.

    .INPUTS
    System.String

    .OUTPUTS
    System.String
    #>
    [CmdletBinding()]
    [OutputType([string])]
    param(
        [Parameter(Mandatory = $true)]
        [AllowEmptyCollection()]
        [string[]]$InputObject,

        [Parameter(Mandatory = $true)]
        [ValidateSet('Platform', 'BuildTools')]
        [string]$PackageType
    )

    $text = $InputObject -join "`n"
    if ($PackageType -eq 'Platform') {
        $versions = @(
            [regex]::Matches($text, '(?m)^\s*platforms/android-(\d+)\s+') |
                ForEach-Object { [int]$_.Groups[1].Value } |
                Sort-Object -Descending -Unique
        )
        if ($versions.Count -eq 0) {
            throw 'No stable Android SDK Platform package was found.'
        }
        return [string]$versions[0]
    }

    $versions = @(
        [regex]::Matches($text, '(?m)^\s*build-tools/([0-9]+\.[0-9]+\.[0-9]+)\s+') |
            ForEach-Object { [version]$_.Groups[1].Value } |
            Sort-Object -Descending -Unique
    )
    if ($versions.Count -eq 0) {
        throw 'No stable Android SDK Build Tools package was found.'
    }
    $versions[0].ToString()
}
