function Set-WUMonitor {
    <#
        .SYNOPSIS
        Change the display settings.

        .DESCRIPTION
        Changes the display refresh rate, resolution, and color depth to the specified values.

        .EXAMPLE
        PS C:\>Set-WUMonitor -MonitorIndex 1 -Frequency 60

        Set the refresh rate of DISPLAY1 to 60.

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
            ValueFromPipeline,
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
        $Frequency
    )

    begin {
        Set-StrictMode -Version 'Latest'

        $monitors = @()
        $monitors += Get-WUMonitor
        if (!$monitors) {
            return
        }
    }

    process {
        $monitors |
        Where-Object {
            if ($PSBoundParameters.ContainsKey('MonitorIndex')) {
                if (!($_.monitorIndex -in [string[]]$MonitorIndex)) {
                    Write-Error ("Cannot find monitor where monitorIndex is {0}." -f (([string[]]$MonitorIndex) -join ' or ')) -ErrorAction $ErrorActionPreference
                    return $false
                }
            }
            if ($PSBoundParameters.ContainsKey('DeviceName')) {
                if (!($_.deviceName -in $DeviceName)) {
                    Write-Error ("Cannot find monitor where deviceName is {0}." -f (([string[]]$DeviceName) -join ' or ')) -ErrorAction $ErrorActionPreference
                    return $false
                }
            }
            return $true
        } |
        ForEach-Object {
            $aMonitor = $_

            if (!$PSBoundParameters.ContainsKey('HorizontalResolution')) {
                $HorizontalResolution = $aMonitor.horizontalResolution
            }
            if (!$PSBoundParameters.ContainsKey('VerticalResolution')) {
                $VerticalResolution = $aMonitor.verticalResolution
            }
            if (!$PSBoundParameters.ContainsKey('BitsPerPixel')) {
                $BitsPerPixel = $aMonitor.bitsPerPixel
            }
            if (!$PSBoundParameters.ContainsKey('Frequency')) {
                $Frequency = $aMonitor.frequency
            }

            $cmd = 'nircmd.exe setdisplay "monitor:{0}" "{1}" "{2}" "{3}" "{4}"' -f $aMonitor.monitorIndex, $HorizontalResolution, $VerticalResolution, $BitsPerPixel, $Frequency
            if ($PSCmdlet.ShouldProcess(("DISPLAY{0}", "Change the horizontal resolution to $HorizontalResolution, the vertical resolution to $VerticalResolution, the color depth to $BitsPerPixel, and the refresh rate to $Frequency." -f $aMonitor.monitorIndex))) {
                $result = ''
                $result = (Invoke-Expression $cmd | ForEach-Object ToString) -join [System.Environment]::NewLine
                Write-Debug ('Command: {0}' -f $cmd)
                Write-Verbose $result
            }
        }
    }
}
