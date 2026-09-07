function Test-WUAndroidEmulatorPort {
    <#
    .SYNOPSIS
    Tests whether Android emulator console ports are available.

    .DESCRIPTION
    Requires adb.exe on PATH. Returns one Boolean for each specified console port in input order. A port is unavailable when adb reports its emulator serial or when its console or adjacent adb TCP port cannot be bound exclusively on the IPv4 or IPv6 loopback address.

    .PARAMETER Port
    Specifies one or more even Android emulator console ports from 5554 through 5682. Accepts pipeline input.

    .EXAMPLE
    Test-WUAndroidEmulatorPort -Port 5554

    Returns whether console port 5554 is available.

    .EXAMPLE
    5554, 5556, 5558 | Test-WUAndroidEmulatorPort

    Returns one Boolean value for each specified console port.

    .INPUTS
    System.Int32

    .OUTPUTS
    System.Boolean
    #>
    [CmdletBinding()]
    [OutputType([bool])]
    param(
        [Parameter(Mandatory = $true, Position = 0, ValueFromPipeline = $true)]
        [ValidateNotNullOrEmpty()]
        [ValidateRange(5554, 5682)]
        [ValidateScript({ $_ % 2 -eq 0 })]
        [int[]]$Port
    )

    begin {
        $unavailablePorts = @(Get-WUAndroidEmulatorUnavailablePort -ErrorAction Stop)
    }

    process {
        foreach ($candidatePort in $Port) {
            $candidatePort -notin $unavailablePorts
        }
    }
}
