function Get-WUAndroidDevice {
    <#
    .SYNOPSIS
    Gets Android hardware profile IDs that can be used to create virtual devices.

    .DESCRIPTION
    The Get-WUAndroidDevice cmdlet gets the hardware profile IDs available to the Android SDK tools. A hardware profile describes a device configuration, such as a Pixel phone, for an AVD.

    .EXAMPLE
    Get-WUAndroidDevice

    Lists the available Android hardware profile IDs.

    .INPUTS
    None

    .OUTPUTS
    System.String
    #>
    [CmdletBinding()]
    [OutputType([string])]
    param()

    Assert-WUCommand -Name 'avdmanager.bat'

    $result = Invoke-WUNativeCommand `
        -Command 'avdmanager.bat' `
        -ArgumentList @('list', 'device', '-c') `
        -CaptureOutput `
        -WhatIf:$false `
        -ErrorAction Stop

    $result.StandardOutput | Split-WUNewLine | ForEach-Object { $_.Trim() } |
        Where-Object { -not [string]::IsNullOrWhiteSpace($_) }
}
