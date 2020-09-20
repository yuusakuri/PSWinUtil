<#
  .DESCRIPTION
  This cmdlet works with registry.
#>

[CmdletBinding(SupportsShouldProcess)]
param (
  [ValidateSet(
    "Magnified",
    "WindowsBlackExtraLarge",
    "WindowsBlackLarge",
    "WindowsBlack",
    "WindowsDefaultExtraLarge",
    "WindowsDefaultLarge",
    "WindowsDefault",
    "WindowsInvertedExtraLarge",
    "WindowsInvertedLarge",
    "WindowsInverted",
    "WindowsStandardExtraLarge",
    "WindowsStandardLarge"
  )]
  [string]
  $PointerScheme
)

Set-StrictMode -Version 'Latest'
$registryHash = Get-WURegistryHash
if (!$registryHash) {
  return
}

Set-WURegistryFromHash -RegistryHash $registryHash -DataKey $PointerScheme
