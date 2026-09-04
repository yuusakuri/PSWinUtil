function Get-WUAndroidEmulator {
    <#
    .SYNOPSIS
    Gets the names of local Android virtual devices.

    .DESCRIPTION
    Finds emulator.exe on PATH and returns every Android virtual device name registered with the local Android SDK, including devices that are not running. Returns no output when no virtual devices are registered.

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

    $emulator = Get-Command -Name 'emulator.exe' -CommandType Application -ErrorAction Ignore |
        Select-Object -First 1
    if ($null -eq $emulator) {
        throw 'Android emulator.exe was not found on PATH.'
    }

    $commandOutput = @(& $emulator.Source '-list-avds' 2>&1)
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
