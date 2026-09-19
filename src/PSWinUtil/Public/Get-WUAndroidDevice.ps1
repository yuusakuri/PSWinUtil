function Get-WUAndroidDevice {
    <#
    .SYNOPSIS
    Gets Android hardware profile IDs that can be used to create virtual devices.

    .DESCRIPTION
    Runs avdmanager.bat list device -c using the command on PATH and returns the hardware profile IDs it reports. These IDs are templates accepted by New-WUAndroidEmulator, not names of AVDs already created; use Get-WUAndroidEmulator for those names.

    .EXAMPLE
    Get-WUAndroidDevice

    Lists hardware profile IDs that New-WUAndroidEmulator accepts for Device.

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
