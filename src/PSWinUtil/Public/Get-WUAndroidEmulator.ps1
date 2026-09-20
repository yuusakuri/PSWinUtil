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

    Assert-WUCommand -Name 'emulator.exe'

    $result = Invoke-WUExternalCommand -Command 'emulator.exe' -ArgumentList @('-list-avds') -CaptureOutput
    if (-not $result.Succeeded) {
        throw "emulator.exe -list-avds failed: $($result.ToDebugString())"
    }

    $avdNames = @(
        $result.StandardOutput | Split-WUNewLine |
            ForEach-Object { $_.Trim() } |
            Where-Object { -not [string]::IsNullOrWhiteSpace($_) }
    )
    $avdNames
}
