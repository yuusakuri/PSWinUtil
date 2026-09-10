function Get-WUAndroidEmulatorUnavailablePort {
    <#
    .SYNOPSIS
    Gets Android emulator console ports that cannot be assigned.

    .DESCRIPTION
    Reads adb devices and tests whether the Android emulator TCP port pairs can be bound on the IPv4 and IPv6 loopback addresses. Returns even console ports from 5554 through 5682 when adb reports the serial or when either the console port or its adjacent adb port cannot be bound. Includes offline and unauthorized devices.

    .EXAMPLE
    Get-WUAndroidEmulatorUnavailablePort

    Gets console ports that cannot be assigned to an emulator.

    .OUTPUTS
    System.Int32
    #>
    [CmdletBinding()]
    [OutputType([int])]
    param()

    Assert-WUCommand -Name 'adb.exe'

    $previousErrorActionPreference = $ErrorActionPreference
    $ErrorActionPreference = 'Continue'
    try {
        $arguments = @('devices')
        $commandOutput = @(& 'adb.exe' @arguments 2>&1)
        $exitCode = $LASTEXITCODE
    } finally {
        $ErrorActionPreference = $previousErrorActionPreference
    }

    if ($exitCode -ne 0) {
        $message = @($commandOutput | ForEach-Object { $_.ToString() }) -join [Environment]::NewLine
        throw "adb.exe devices failed with exit code $exitCode.$([Environment]::NewLine)$message"
    }

    $unavailablePorts = @(
        foreach ($line in $commandOutput) {
            if ($line.ToString() -match '^emulator-([0-9]{4})\s+\S+') {
                $port = [int]$Matches[1]
                if ($port -ge 5554 -and $port -le 5682 -and $port % 2 -eq 0) {
                    $port
                }
            }
        }
        $androidPorts = [int[]](5554..5683)
        $ipv4Results = @(
            Test-WUTcpPort -LocalAddress ([System.Net.IPAddress]::Loopback) -Port $androidPorts -ErrorAction Stop
        )
        $ipv6Results = @(
            Test-WUTcpPort -LocalAddress ([System.Net.IPAddress]::IPv6Loopback) -Port $androidPorts -ErrorAction Stop
        )
        for ($index = 0; $index -lt $androidPorts.Count; $index++) {
            if (-not $ipv4Results[$index] -or -not $ipv6Results[$index]) {
                $androidPorts[$index] - ($androidPorts[$index] % 2)
            }
        }
    )
    $unavailablePorts | Sort-Object -Unique
}
