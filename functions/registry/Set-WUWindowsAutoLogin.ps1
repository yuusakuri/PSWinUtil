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
  $registryHash.Enable.Machine.Data = $registryHash.Enable.Machine.Data.Enable
}
else {
  $registryHash.Enable.Machine.Data = $registryHash.Enable.Machine.Data.Disable
}

Set-WURegistryFromHash -RegistryHash $registryHash
