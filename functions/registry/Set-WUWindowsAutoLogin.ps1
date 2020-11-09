<#
  .DESCRIPTION
  This cmdlet works with registry.
#>

[CmdletBinding(SupportsShouldProcess)]
param (
  [string]
  $Username,
  [string]
  $Password
)

Set-StrictMode -Version 'Latest'
$registryHash = Get-WURegistryHash
if (!$registryHash) {
  return
}

$registryHash.Username.Machine.Data = $Username
$registryHash.Password.Machine.Data = $Password

if ($Username) {
  $registryHash.Enable1.Machine.Data = $registryHash.Enable1.Machine.Data.Enable
  $registryHash.Enable2.Machine.Data = $registryHash.Enable2.Machine.Data.Enable
}
else {
  $registryHash.Enable1.Machine.Data = $registryHash.Enable1.Machine.Data.Disable
  $registryHash.Enable2.Machine.Data = $registryHash.Enable2.Machine.Data.Disable
}

Set-WURegistryFromHash -RegistryHash $registryHash
