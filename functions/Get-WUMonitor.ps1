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

$tempDirPath = (New-CTempDirectory).FullName
try {
  $xmlPath = "$tempPath\MonitorTool.xml"

  Start-Process 'MultiMonitorTool.exe' ('/sxml "{0}"' -f $xmlPath) -Wait -NoNewWindow

  [xml]$xmlo = Get-Content -LiteralPath $xmlPath

  return $xmlo.monitors_list.item
}
finally {
  # tempを削除
  $tempDirPath |
  Where-Object { Test-Path -LiteralPath $_ } |
  Remove-Item -Recurse -Force
}
