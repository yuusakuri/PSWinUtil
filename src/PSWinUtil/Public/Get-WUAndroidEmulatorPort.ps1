function Get-WUAndroidEmulatorPort {
    <#
    .SYNOPSIS
    Gets available Android emulator console ports.

    .DESCRIPTION
    Requires adb.exe on PATH. Returns the requested number of distinct even console ports from 5554 through 5682 in ascending order. A port is unavailable when adb reports its emulator serial or when its console or adjacent adb TCP port cannot be bound exclusively on the IPv4 or IPv6 loopback address. Throws when fewer ports are available than requested.

    .PARAMETER Count
    Specifies the number of available console ports to return, from 1 through 64. The default is 1.

    .EXAMPLE
    $port = Get-WUAndroidEmulatorPort
    Start-WUAndroidEmulator -Name 'Example_API_35' -Port $port

    Starts Example_API_35 on the first available emulator console port.

    .EXAMPLE
    Get-WUAndroidEmulatorPort -Count 3

    Gets three distinct available emulator console ports.

    .INPUTS
    None

    .OUTPUTS
    System.Int32
    #>
    [CmdletBinding()]
    [OutputType([int])]
    param(
        [Parameter()]
        [ValidateRange(1, 64)]
        [int]$Count = 1
    )

    $unavailablePorts = @(Get-WUAndroidEmulatorUnavailablePort -ErrorAction Stop)
    Select-WUAndroidEmulatorPort -UnavailablePort $unavailablePorts -Count $Count
}
