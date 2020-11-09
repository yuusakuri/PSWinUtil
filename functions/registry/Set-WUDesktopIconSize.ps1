﻿<#
  .DESCRIPTION
  This cmdlet works with registry.
#>

[CmdletBinding(SupportsShouldProcess)]
param (
  [ValidateSet('ExtraLarge', 'Large', 'Medium', 'Small')]
  $Size
)

Set-StrictMode -Version 'Latest'
$registryHash = Get-WURegistryHash
if (!$registryHash) {
  return
}

Set-WURegistryFromHash -RegistryHash $registryHash -DataKey $Size