function Assert-WUAndroidEmulatorRunning {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [object[]]$Emulator
    )

    foreach ($item in $Emulator) {
        $item.Process.Refresh()
        if ($item.Process.HasExited) {
            throw "$($item.Serial) exited before becoming available to adb with exit code $($item.Process.ExitCode)."
        }
    }
}
