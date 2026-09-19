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

    $savedErrorActionPreference = $ErrorActionPreference
    try {
        $ErrorActionPreference = 'Continue'
        $commandOutput = @(& 'avdmanager.bat' list device -c 2>&1)
        $exitCode = $LASTEXITCODE
    } finally {
        $ErrorActionPreference = $savedErrorActionPreference
    }
    if ($exitCode -ne 0) {
        $message = ($commandOutput | ForEach-Object { $_.ToString() }) -join [Environment]::NewLine
        throw "avdmanager list device failed with exit code $exitCode.$([Environment]::NewLine)$message"
    }

    $commandOutput | ForEach-Object { $_.ToString().Trim() } |
        Where-Object { -not [string]::IsNullOrWhiteSpace($_) }
}
