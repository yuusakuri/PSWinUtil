function Get-WUAndroidEmulator {
    <#
    .SYNOPSIS
    Lists Android virtual device names that the emulator can start.

    .DESCRIPTION
    Runs emulator.exe -list-avds using the command on PATH and returns the AVD names it reports, including devices that are not running. Returns no output when the command reports no AVDs. These are created virtual devices, not the hardware profile IDs returned by Get-WUAndroidDevice.

    .EXAMPLE
    Get-WUAndroidEmulator

    Lists all local Android virtual device names without starting them.

    .INPUTS
    None

    .OUTPUTS
    System.String
    #>
    [CmdletBinding()]
    [OutputType([string])]
    param()

    Assert-WUCommand -Name 'emulator.exe'

    $arguments = @('-list-avds')
    $commandOutput = @(& 'emulator.exe' @arguments 2>&1)
    $exitCode = $LASTEXITCODE
    if ($exitCode -ne 0) {
        $message = @($commandOutput | ForEach-Object { $_.ToString() }) -join [Environment]::NewLine
        throw "emulator.exe -list-avds failed with exit code $exitCode.$([Environment]::NewLine)$message"
    }

    $avdNames = @(
        $commandOutput |
            ForEach-Object { $_.ToString().Trim() } |
            Where-Object { -not [string]::IsNullOrWhiteSpace($_) }
    )
    $avdNames
}
