<#
  .DESCRIPTION
  This cmdlet works with registry.
#>

[CmdletBinding(SupportsShouldProcess)]
param (
  # Specifies a path to one or more locations. Wildcards are permitted.
  [Parameter(Mandatory,
    Position = 0,
    ParameterSetName = 'Path',
    ValueFromPipeline,
    ValueFromPipelineByPropertyName)]
  [ValidateNotNullOrEmpty()]
  [SupportsWildcards()]
  [string[]]
  $Path,

  # Specifies a path to one or more locations. Unlike the Path parameter, the value of the LiteralPath parameter is used exactly as it is typed. No characters are interpreted as wildcards. If the path includes escape characters, enclose it in single quotation marks. Single quotation marks tell Windows PowerShell not to interpret any characters as escape sequences.
  [Parameter(Mandatory,
    Position = 0,
    ParameterSetName = 'LiteralPath',
    ValueFromPipelineByPropertyName)]
  [Alias('PSPath')]
  [ValidateNotNullOrEmpty()]
  [string[]]
  $LiteralPath,

  [ValidateSet(
    "Application",
    "System",
    "SystemEnhanced"
  )]
  [string]
  $ScalingBehavior,

  # Specify the target user. The target is the current user if you specify 'User', and all users if you specify 'Machine'. The default value is 'User'.
  [ValidateSet('User', 'Machine')]
  [string]
  $Scope = 'User'
)

Set-StrictMode -Version 'Latest'

$paths = @()
if ($psCmdlet.ParameterSetName -eq 'Path') {
  $paths += Resolve-WUFullPath -Path $Path
}
else {
  $paths += Resolve-WUFullPath -LiteralPath $LiteralPath
}

foreach ($aPath in $paths) {
  $registryHash = Get-WURegistryHash
  if (!$registryHash) {
    return
  }

  $registryHash.ScalingBehavior.$Scope.ValueName = $aPath

  Set-WURegistryFromHash -RegistryHash $registryHash -Scope $Scope -DataKey $ScalingBehavior
}
