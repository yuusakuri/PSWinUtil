<#
  .DESCRIPTION
  This cmdlet works with registry.
#>

[CmdletBinding(SupportsShouldProcess)]
param (
  # Specify the target user. The target is the current user if you specify 'User', and all users if you specify 'Machine'. The default value is 'User'.
  [ValidateSet('User', 'Machine')]
  [string]
  $Scope = 'User'
)

Set-StrictMode -Version 'Latest'
$registryHash = Get-WURegistryHash
if (!$registryHash) {
  return
}

Set-WURegistryFromHash -RegistryHash $registryHash -Scope $Scope -DataKey $MyInvocation.MyCommand.Verb
