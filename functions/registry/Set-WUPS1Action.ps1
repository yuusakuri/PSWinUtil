<#
  .DESCRIPTION
  This cmdlet works with registry.
#>

[CmdletBinding(SupportsShouldProcess)]
param (
  [ValidateSet('Run', 'Edit')]
  [string]
  $PS1Action
)

Set-StrictMode -Version 'Latest'
$registryHash = Get-WURegistryHash
if (!$registryHash) {
  return
}

Set-WURegistryFromHash -RegistryHash $registryHash -DataKey $PS1Action
