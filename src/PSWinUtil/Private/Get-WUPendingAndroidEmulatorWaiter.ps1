function Get-WUPendingAndroidEmulatorWaiter {
    [CmdletBinding()]
    [OutputType([object])]
    param(
        [Parameter(Mandatory = $true)]
        [object[]]$Waiter
    )

    foreach ($item in $Waiter) {
        $item.Process.Refresh()
        if (-not $item.Process.HasExited) {
            $item
            continue
        }

        if ($item.Process.ExitCode -ne 0) {
            throw "adb wait-for-device for $($item.Serial) exited with code $($item.Process.ExitCode)."
        }
    }
}
