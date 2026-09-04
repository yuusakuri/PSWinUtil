function Start-WUAndroidEmulator {
    <#
    .SYNOPSIS
    Starts local Android virtual devices.

    .DESCRIPTION
    Finds emulator.exe on PATH and starts each selected Android virtual device in a background process. When Name is omitted, all local virtual devices are started. Returns a process for each device started.

    .PARAMETER Name
    Specifies an Android virtual device name returned by Get-WUAndroidVirtualDevice. When omitted, all local virtual devices are started.

    .EXAMPLE
    Start-WUAndroidEmulator -Name 'Pixel_API_35'

    Starts the Android virtual device named Pixel_API_35.

    .EXAMPLE
    Start-WUAndroidEmulator

    Starts all local Android virtual devices.

    .INPUTS
    None

    .OUTPUTS
    System.Diagnostics.Process
    #>
    [CmdletBinding(SupportsShouldProcess = $true)]
    [OutputType([System.Diagnostics.Process])]
    param(
        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [string]$Name
    )

    $emulator = Get-Command -Name 'emulator.exe' -CommandType Application -ErrorAction Ignore |
        Select-Object -First 1
    if ($null -eq $emulator) {
        throw 'Android emulator.exe was not found on PATH.'
    }

    $avdNames = @(Get-WUAndroidVirtualDevice -ErrorAction Stop)
    if ($avdNames.Count -eq 0) {
        throw 'No Android virtual device is available.'
    }

    $selectedNames = $avdNames
    if ($PSBoundParameters.ContainsKey('Name')) {
        $matchingNames = @($avdNames | Where-Object { $_ -eq $Name })
        if ($matchingNames.Count -eq 0) {
            throw "The Android virtual device was not found: $Name"
        }
        $selectedNames = $matchingNames
    }

    foreach ($selectedName in $selectedNames) {
        $target = "Android virtual device '$selectedName'"
        if ($PSCmdlet.ShouldProcess($target, 'Start Android emulator')) {
            Start-Process -FilePath $emulator.Source -ArgumentList "@$selectedName" -PassThru -ErrorAction Stop
        }
    }
}
