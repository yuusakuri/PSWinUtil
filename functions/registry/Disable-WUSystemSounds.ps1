<#
  .DESCRIPTION
  This cmdlet works with registry.
#>

[CmdletBinding(SupportsShouldProcess)]
param (
)

Set-StrictMode -Version 'Latest'
$registryHash = Get-WURegistryHash
if (!$registryHash) {
  return
}

Set-WURegistryFromHash -RegistryHash $registryHash -DataKey $MyInvocation.MyCommand.Verb

$value = ""
Get-ChildItem -Path "HKCU:\AppEvents\Schemes\Apps" |
Get-ChildItem |
ForEach-Object {
  Get-ChildItem  $_.PSPath | Where-Object { $_.PSChildName -eq ".Current" } |
  Get-ItemProperty | Where-Object { $_ | Get-Member -Name "(Default)" } |
  Set-ItemProperty -Name "(Default)" -Value $value
}
