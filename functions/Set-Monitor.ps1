function Set-WUMonitor {
    <#
        .SYNOPSIS
        Change the display settings.

        .DESCRIPTION
        Changes the display refresh rate, resolution, and color depth to the specified values.

        .EXAMPLE
        PS C:\>Set-WUMonitor -MonitorIndex 1 -Frequency 60

        Set the refresh rate of DISPLAY1 to 60.

        .EXAMPLE
        PS C:\>Get-WUMonitor | Where-Object { $_.primary -eq $true } | Set-WUMonitor -Frequency 60

        Set the refresh rate of primary monitor to 60.

        .LINK
        Get-WUMonitor
    #>

    [CmdletBinding(SupportsShouldProcess,
        DefaultParameterSetName = 'MonitorIndex')]
    param (
        # Specify the monitor 1-based numbers.
        [Parameter(Position = 0,
            ParameterSetName = 'MonitorIndex',
            ValueFromPipeline,
            ValueFromPipelineByPropertyName)]
        [ValidateNotNullOrEmpty()]
        [int[]]
        $MonitorIndex,

        # Specify the monitor device name. Example: `\\.\DISPLAY1`
        [Parameter(Position = 0,
            ParameterSetName = 'DeviceName',
            ValueFromPipelineByPropertyName)]
        [string[]]
        $DeviceName,

        # Specify horizontal resolution.
        [int]
        $HorizontalResolution,

        # Specify vertical resolution.
        [int]
        $VerticalResolution,

        # Specify color depth (bits per pixel).
        [int]
        $BitsPerPixel,

        # Specify frequency (refresh rate).
        [Alias('RefreshRate')]
        [int]
        $Frequency,

        # Set the resolution and refresh rate to the highest values.
        [switch]
        $HighestQuality
    )

    begin {
        Set-StrictMode -Version 'Latest'

        $monitors = @()
        $monitors += Get-WUMonitor
        if (!$monitors) {
            Write-Error "Cannot find any monitor information."
            return
        }
    }

    process {
        $matchingMonitors = @()
        $matchingMonitors += $monitors |
        Where-Object {
            if ($PSBoundParameters.ContainsKey('MonitorIndex')) {
                if (!($_.monitorIndex -in [string[]]$MonitorIndex)) {
                    return $false
                }
            }
            if ($PSBoundParameters.ContainsKey('DeviceName')) {
                if (!($_.deviceName -in $DeviceName)) {
                    return $false
                }
            }
            return $true
        }

        if (!$matchingMonitors) {
            Write-Error "No matching monitor found." -ErrorAction $ErrorActionPreference
            return
        }

        $matchingMonitors |
        ForEach-Object {
            $aMonitor = $_

            if ($HighestQuality) {
                $bestDisplayMode = $aMonitor.supportedDisplayModes |
                Select-Object -Last 1

                $HorizontalResolution = $bestDisplayMode.horizontalResolution
                $VerticalResolution = $bestDisplayMode.verticalResolution
                $Frequency = $bestDisplayMode.frequency
            }
            else {
                if (!$PSBoundParameters.ContainsKey('HorizontalResolution')) {
                    $HorizontalResolution = $aMonitor.horizontalResolution
                }
                if (!$PSBoundParameters.ContainsKey('VerticalResolution')) {
                    $VerticalResolution = $aMonitor.verticalResolution
                }
                if (!$PSBoundParameters.ContainsKey('Frequency')) {
                    $Frequency = $aMonitor.frequency
                }
            }
            if (!$PSBoundParameters.ContainsKey('BitsPerPixel')) {
                $BitsPerPixel = $aMonitor.bitsPerPixel
            }
            $monitorIndexForSetdisplay = ([int]$aMonitor.monitorIndex) - 1

            $cmd = 'nircmd.exe setdisplay "monitor:{0}" "{1}" "{2}" "{3}" "{4}"' -f $monitorIndexForSetdisplay, $HorizontalResolution, $VerticalResolution, $BitsPerPixel, $Frequency
            if ($PSCmdlet.ShouldProcess(("DISPLAY{0}", "Change the horizontal resolution to $HorizontalResolution, the vertical resolution to $VerticalResolution, the color depth to $BitsPerPixel, and the refresh rate to $Frequency." -f $monitorIndexForSetdisplay))) {
                $result = ''
                $result = (Invoke-Expression $cmd | ForEach-Object ToString) -join [System.Environment]::NewLine
                Write-Debug ('Command: {0}' -f $cmd)
                if ($result) {
                    Write-Verbose $result
                }
            }
        }
    }
}
