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

$xmlPath = "$env:TEMP/MonitorTool-{0}.xml" -f (Get-WURandomString -Length 8)

MultiMonitorTool.exe /sxml $xmlPath

# ファイル作成を約60秒まで待つ
$limit = 60
for ($i = 0; $i -lt $limit; $i++) {
  if ((Test-Path -LiteralPath $xmlPath)) {
    break
  }
  if ($i -eq $limit - 1) {
    Write-Error "Failed to write monitor information to path '$xmlPath'."
    return
  }
  Start-Sleep 1
}

[xml]$xmlo = Get-Content -LiteralPath $xmlPath

Remove-Item -LiteralPath $xmlPath -Force

return $xmlo.monitors_list.item
