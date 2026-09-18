function Get-WUAndroidDevice {
    <#
    .SYNOPSIS
    Gets Android hardware profile IDs that can be used to create virtual devices.

    .DESCRIPTION
    Requires avdmanager.bat on PATH. Returns the installed Android SDK Command-Line Tools hardware profile IDs after trimming whitespace and removing blank lines. These are creation templates, not the names of existing virtual devices returned by Get-WUAndroidEmulator.

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
