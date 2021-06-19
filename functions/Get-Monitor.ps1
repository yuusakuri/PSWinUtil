function Get-WUMonitor {
    <#
        .SYNOPSIS
        Get Monitor details.

        .DESCRIPTION
        Get monitor's name, resolution, frequency, id, key, etc. Supports multiple monitors.

        .OUTPUTS
        System.Xml.XmlElement.

        .EXAMPLE
        PS C:\>Get-WUMonitor

        Get details of all monitors.

        .LINK
        Set-WUMonitor

        .Notes
        Get-CimInstance -ClassName Win32_VideoController
        Get-CimInstance -ClassName Win32_PnPEntity | Where-Object Service -eq Monitor
        Get-CimInstance -Namespace root\wmi -ClassName WmiMonitorBasicDisplayParams
        MonitorInfoView.exe /sxml $xmlPath
    #>

    [CmdletBinding()]
    param (
    )

    Set-StrictMode -Version 'Latest'

    $tempDirPath = (Carbon\New-CTempDirectory).FullName
    if (!(Test-Path -LiteralPath $tempDirPath)) {
        return
    }
    try {
        $xmlPath = Join-Path $tempDirPath 'MonitorTool.xml'

        Start-Process 'MultiMonitorTool.exe' ('/sxml "{0}"' -f (($xmlPath | Convert-WUString -Type EscapeForPowerShellDoubleQuotation))) -Wait -NoNewWindow

        $xmlo = $null
        [xml]$xmlo = Get-Content -LiteralPath $xmlPath
        if (!$xmlo) {
            return
        }

        return $xmlo.monitors_list.item
    }
    finally {
        $tempDirPath |
        Where-Object { Test-Path -LiteralPath $_ } |
        Remove-Item -LiteralPath { $_ } -Recurse -Force
    }
}
