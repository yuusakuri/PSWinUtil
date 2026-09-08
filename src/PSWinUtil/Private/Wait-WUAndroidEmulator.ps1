function Wait-WUAndroidEmulator {
    <#
    .SYNOPSIS
    Waits for Android emulators to become available to adb.

    .DESCRIPTION
    Starts adb wait-for-device for every specified emulator, then waits up to the specified time for all devices to become available to adb. Monitors each emulator process while waiting. Stops unfinished adb waiter processes when the time limit expires.

    .PARAMETER Emulator
    Specifies started emulator records with Name, Port, Serial, and Process properties.

    .PARAMETER TimeoutSeconds
    Specifies the time limit for the whole group in seconds, from 1 through 3600. The default is 300.

    .EXAMPLE
    Wait-WUAndroidEmulator -Emulator $startedEmulators

    Waits up to five minutes for all specified emulators to become available to adb.

    .OUTPUTS
    None
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [object[]]$Emulator,

        [Parameter()]
        [ValidateRange(1, 3600)]
        [int]$TimeoutSeconds = 300
    )

    $waiters = [System.Collections.Generic.List[object]]::new()
    $stopwatch = $null
    $stopPendingWaiters = $false
    try {
        foreach ($item in $Emulator) {
            $arguments = @('-s', $item.Serial, 'wait-for-device')
            $startParameters = @{
                FilePath = 'adb.exe'
                ArgumentList = $arguments
                PassThru = $true
                NoNewWindow = $true
                ErrorAction = 'Stop'
            }
            $process = Start-Process @startParameters
            $waiters.Add([pscustomobject]@{
                    Serial = $item.Serial
                    Process = $process
                })
        }

        $stopwatch = [System.Diagnostics.Stopwatch]::StartNew()
        while ($true) {
            foreach ($item in $Emulator) {
                $item.Process.Refresh()
                if ($item.Process.HasExited) {
                    throw "$($item.Serial) exited before becoming available to adb with exit code $($item.Process.ExitCode)."
                }
            }

            $pendingWaiters = @(
                foreach ($waiter in $waiters) {
                    $waiter.Process.Refresh()
                    if ($waiter.Process.HasExited) {
                        if ($waiter.Process.ExitCode -ne 0) {
                            throw "adb wait-for-device for $($waiter.Serial) exited with code $($waiter.Process.ExitCode)."
                        }
                    } else {
                        $waiter
                    }
                }
            )
            if ($pendingWaiters.Count -eq 0) {
                return
            }
            if ($stopwatch.Elapsed.TotalSeconds -ge $TimeoutSeconds) {
                $pendingSerials = @($pendingWaiters.Serial) -join ', '
                $stopPendingWaiters = $true
                throw "Timed out waiting for Android emulators to become available to adb after $TimeoutSeconds seconds: $pendingSerials"
            }

            Start-Sleep -Milliseconds 100
        }
    } finally {
        if ($null -ne $stopwatch) {
            $stopwatch.Stop()
        }
        foreach ($waiter in $waiters) {
            $waiter.Process.Refresh()
            if ($stopPendingWaiters -and -not $waiter.Process.HasExited) {
                Stop-Process -Id $waiter.Process.Id -Force -ErrorAction SilentlyContinue
                $waiter.Process.WaitForExit()
            }
            if ($waiter.Process -is [System.IDisposable]) {
                $waiter.Process.Dispose()
            }
        }
    }
}
