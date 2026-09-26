function Get-WUAndroidSystemImage {
    <#
    .SYNOPSIS
    Gets available Android system image packages.

    .DESCRIPTION
    Gets stable Android system image packages reported by the Android SDK for the selected image tag, ABI, and optional API level.

    .PARAMETER PlatformVersion
    Specifies an Android API level to include.

    .PARAMETER SystemImageTag
    Specifies an image variant such as google_apis, google_apis_playstore, or default.

    .PARAMETER Abi
    Specifies a system image CPU ABI.

    .EXAMPLE
    Get-WUAndroidSystemImage

    Lists stable system image packages available in the Android SDK.

    .EXAMPLE
    Get-WUAndroidSystemImage -PlatformVersion 35 -SystemImageTag google_apis -Abi x86_64

    Lists stable x86_64 Google APIs images for Android API 35.

    .INPUTS
    None

    .OUTPUTS
    PSWinUtil.AndroidSystemImage
    #>
    [CmdletBinding()]
    [OutputType([PSWinUtil.AndroidSystemImage])]
    param(
        [Parameter()]
        [ValidateRange(1, 2147483647)]
        [int]$PlatformVersion,

        [Parameter()]
        [ValidatePattern('^[a-z0-9_]+$')]
        [string]$SystemImageTag,

        [Parameter()]
        [ValidateSet('x86_64', 'arm64-v8a', 'x86', 'armeabi-v7a')]
        [string]$Abi
    )

    Assert-WUCommand -Name 'android'

    $commandParameters = @{
        Command = 'android'
        ArgumentList = @('--no-metrics', 'sdk', 'list', 'system-images/*', '--all', '--all-versions')
        CaptureOutput = $true
        ContinueExitCodes = @(-1073740791)
        WhatIf = $false
        ErrorAction = 'Stop'
    }
    $result = Invoke-WUNativeCommand @commandParameters

    foreach ($line in ($result.StandardOutput | Split-WUNewLine)) {
        if ($line -notmatch '^\s*system-images/android-([0-9]+)/([^/\s]+)/([^\s]+)\s+([0-9]+\.[0-9]+\.[0-9]+)\s+') {
            continue
        }

        $image = [PSWinUtil.AndroidSystemImage]::new(
            [int]$Matches[1],
            $Matches[2],
            $Matches[3],
            $Matches[4]
        )
        if ($PSBoundParameters.ContainsKey('PlatformVersion') -and
            $image.PlatformVersion -ne $PlatformVersion) {
            continue
        }
        if ($PSBoundParameters.ContainsKey('SystemImageTag') -and
            $image.SystemImageTag -cne $SystemImageTag) {
            continue
        }
        if ($PSBoundParameters.ContainsKey('Abi') -and $image.Abi -cne $Abi) {
            continue
        }

        $image
    }
}
