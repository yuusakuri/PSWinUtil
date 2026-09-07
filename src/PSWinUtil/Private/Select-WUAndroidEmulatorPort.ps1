function Select-WUAndroidEmulatorPort {
    <#
    .SYNOPSIS
    Selects available Android emulator console ports.

    .DESCRIPTION
    Checks even ports from 5554 through 5682 in ascending order and returns Count ports absent from UnavailablePort. Throws when fewer ports are available than requested.

    .PARAMETER UnavailablePort
    Specifies console ports that cannot be assigned to emulators.

    .PARAMETER Count
    Specifies the number of ports to select, from 1 through 64. The default is 1.

    .EXAMPLE
    Select-WUAndroidEmulatorPort -UnavailablePort 5554, 5558

    Returns 5556.

    .OUTPUTS
    System.Int32
    #>
    [CmdletBinding()]
    [OutputType([int])]
    param(
        [Parameter()]
        [int[]]$UnavailablePort = @(),

        [Parameter()]
        [ValidateRange(1, 64)]
        [int]$Count = 1
    )

    $availablePorts = @(
        for ($candidatePort = 5554; $candidatePort -le 5682; $candidatePort += 2) {
            if ($candidatePort -notin $UnavailablePort) {
                $candidatePort
            }
        }
    )
    if ($availablePorts.Count -lt $Count) {
        throw "Only $($availablePorts.Count) Android emulator console ports are available, but $Count were requested."
    }

    $availablePorts | Select-Object -First $Count
}
