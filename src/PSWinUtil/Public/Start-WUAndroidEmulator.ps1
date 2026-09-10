function Start-WUAndroidEmulator {
    <#
    .SYNOPSIS
    Starts one or more local Android virtual devices.

    .DESCRIPTION
    Requires emulator.exe and adb.exe on PATH. Allocates distinct available ports and starts the selected virtual devices. When Name is omitted, starts all local virtual devices. By default, waits up to five minutes for all selected devices to become available to adb, then returns their processes.

    .PARAMETER Name
    Specifies one or more Android virtual device names returned by Get-WUAndroidEmulator. Supports dynamic tab completion. When omitted, all local virtual devices are started.

    .PARAMETER Port
    Specifies an even console port from 5554 through 5682. Requires exactly one Name. When omitted, selects available ports in ascending order. Throws before launching any process if the specified port is unavailable or too few ports are available for the selected devices.

    .PARAMETER NoWait
    Returns all processes immediately after launching all selected devices.

    .EXAMPLE
    Start-WUAndroidEmulator -Name 'Pixel_API_35'

    Starts Pixel_API_35 on an automatically selected port and waits for it to become available to adb.

    .EXAMPLE
    Start-WUAndroidEmulator -Name 'Example_API_35' -Port 5554

    Starts Example_API_35 with serial emulator-5554 and waits for it to become available to adb.

    .EXAMPLE
    Start-WUAndroidEmulator -Name 'Example_API_35' -NoWait

    Starts Example_API_35 on an automatically selected port and returns immediately.

    .EXAMPLE
    Start-WUAndroidEmulator -Name 'Phone API 35', 'Tablet API 35'

    Starts the two specified virtual devices on different automatically selected ports and waits for both to become available to adb.

    .EXAMPLE
    Start-WUAndroidEmulator

    Starts every local Android virtual device, then waits for all devices to become available to adb.

    .INPUTS
    None

    .OUTPUTS
    System.Diagnostics.Process
    #>
    [CmdletBinding(SupportsShouldProcess = $true)]
    [OutputType([System.Diagnostics.Process])]
    param(
        [Parameter()]
        [ArgumentCompleter({
                # PowerShell supplies the completion prefix as the third argument.
                $wordToComplete = [string]$args[2]

                try {
                    $names = @(Get-WUAndroidEmulator -ErrorAction Stop)
                    foreach ($avdName in $names) {
                        if ($avdName.StartsWith($wordToComplete.Trim("'`""), [StringComparison]::OrdinalIgnoreCase)) {
                            [System.Management.Automation.CompletionResult]::new(
                                (ConvertTo-WUPSStringLiteral -InputObject $avdName),
                                $avdName,
                                [System.Management.Automation.CompletionResultType]::ParameterValue,
                                $avdName
                            )
                        }
                    }
                } catch {
                    Write-Verbose -Message "Android virtual device completion failed. $($_.Exception.Message)"
                }
            })]
        [ValidateNotNullOrEmpty()]
        [string[]]$Name,

        [Parameter()]
        [ValidateRange(5554, 5682)]
        [ValidateScript({ $_ % 2 -eq 0 })]
        [int]$Port,

        [Parameter()]
        [switch]$NoWait
    )

    if ($PSBoundParameters.ContainsKey('Port') -and
        (-not $PSBoundParameters.ContainsKey('Name') -or $Name.Count -ne 1)) {
        throw 'Port requires exactly one Name.'
    }

    Assert-WUCommand -Name 'emulator.exe'

    $avdNames = @(Get-WUAndroidEmulator -ErrorAction Stop)
    if ($avdNames.Count -eq 0) {
        throw 'No Android virtual device is available.'
    }

    $selectedNames = @($avdNames)
    if ($PSBoundParameters.ContainsKey('Name')) {
        $selectedNames = @(
            foreach ($requestedName in $Name) {
                $matchingNames = @($avdNames | Where-Object { $_ -eq $requestedName })
                if ($matchingNames.Count -eq 0) {
                    throw "The Android virtual device was not found: $requestedName"
                }
                $matchingNames[0]
            }
        )
        if (@($selectedNames | Select-Object -Unique).Count -ne $selectedNames.Count) {
            throw 'Each Android virtual device name can be specified only once.'
        }
    }

    Assert-WUCommand -Name 'adb.exe'

    $approvedNames = @(
        foreach ($selectedName in $selectedNames) {
            $target = "Android virtual device '$selectedName'"
            if ($PSCmdlet.ShouldProcess($target, 'Start Android emulator')) {
                $selectedName
            }
        }
    )
    if ($approvedNames.Count -eq 0) {
        return
    }

    $unavailablePorts = @(Get-WUAndroidEmulatorUnavailablePort -ErrorAction Stop)
    if ($PSBoundParameters.ContainsKey('Port')) {
        if ($Port -in $unavailablePorts) {
            throw "Android emulator console port $Port is unavailable."
        }
        $selectedPorts = @($Port)
    } else {
        $selectedPorts = @(Select-WUAndroidEmulatorPort -UnavailablePort $unavailablePorts -Count $approvedNames.Count)
    }

    $startedEmulators = [System.Collections.Generic.List[object]]::new()
    for ($index = 0; $index -lt $approvedNames.Count; $index++) {
        $selectedName = $approvedNames[$index]
        $selectedPort = $selectedPorts[$index]
        $nameArgument = ConvertTo-WUWindowsCommandLineArgument -Argument $selectedName -AlwaysQuote
        $arguments = @('-avd', $nameArgument, '-port', [string]$selectedPort)
        $process = Start-Process -FilePath 'emulator.exe' -ArgumentList $arguments -PassThru -ErrorAction Stop
        $startedEmulator = [pscustomobject]@{
            Name = $selectedName
            Port = $selectedPort
            Serial = "emulator-$selectedPort"
            Process = $process
        }
        $startedEmulators.Add($startedEmulator)
    }

    if (-not $NoWait) {
        Wait-WUAndroidEmulator -Emulator $startedEmulators.ToArray() -ErrorAction Stop
    }
    $startedEmulators | ForEach-Object { $_.Process }
}
