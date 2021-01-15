<#
    .SYNOPSIS
    Change the display settings.

    .DESCRIPTION
    Changes the display refresh rate, resolution, and color depth to the specified values.

    .EXAMPLE
    PS C:\>Set-WUMonitor -MonitorIndex 1 -RefreshRate 60

    Set the refresh rate of DISPLAY1 to 60.

    .LINK
    Get-WUMonitor
#>

[CmdletBinding(SupportsShouldProcess)]
param (
    # Specify the monitor number.
    [Parameter(Position = 0,
        ValueFromPipeline,
        ValueFromPipelineByPropertyName)]
    [int]
    $MonitorIndex,

    # Specify horizontal resolution.
    [int]
    $HorizontalResolution,

    # Specify vertical resolution.
    [int]
    $VerticalResolution,

    # Specify color bits.
    [int]
    $ColorBits,

    # Specify refresh rate.
    [Alias('Frequency')]
    [int]
    $RefreshRate
)

Set-StrictMode -Version 'Latest'

[array]$monitors = Get-WUMonitor |
Where-Object {
    if ($PSBoundParameters.ContainsKey('MonitorIndex')) {
        return [regex]::Matches($_.name, '\d+').Value -eq [string]$MonitorIndex
    }
    return $true
}

if (!$monitors) {
    Write-Error 'Cannot find monitors that match the conditions.'
    return
}

foreach ($monitor in $monitors) {
    $aMonitorIndex = [regex]::Matches($monitor.name, '\d+').Value
    if (!$PSBoundParameters.ContainsKey('HorizontalResolution')) {
        $HorizontalResolution = $monitor.resolution -replace ' X .+', ''
    }
    if (!$PSBoundParameters.ContainsKey('VerticalResolution')) {
        $VerticalResolution = $monitor.resolution -replace '.+ X ', ''
    }
    if (!$PSBoundParameters.ContainsKey('ColorBits')) {
        $ColorBits = $monitor.colors
    }
    if (!$PSBoundParameters.ContainsKey('frequency')) {
        $RefreshRate = $monitor.frequency
    }

    if ($pscmdlet.ShouldProcess("DISPLAY$aMonitorIndex", "Change the horizontal resolution to $HorizontalResolution, the vertical resolution to $VerticalResolution, the color depth to $ColorBits, and the refresh rate to $RefreshRate.")) {
        nircmd.exe setdisplay "monitor:$aMonitorIndex" "$HorizontalResolution" "$VerticalResolution" "$ColorBits" "$RefreshRate"
    }
}
