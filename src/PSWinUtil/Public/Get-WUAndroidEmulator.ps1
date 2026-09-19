function Get-WUAndroidEmulator {
    <#
    .SYNOPSIS
    Lists Android virtual device names that the emulator can start.

    .DESCRIPTION
    Returns created AVD names, including stopped devices, for the Name parameter of Start-WUAndroidEmulator.

    .EXAMPLE
    Get-WUAndroidEmulator

    Lists the names of created Android virtual devices.

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
