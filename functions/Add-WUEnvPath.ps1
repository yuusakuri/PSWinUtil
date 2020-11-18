<#
  .SYNOPSIS
  Adds the specified path to the path environment variable.

  .DESCRIPTION
  Adds the specified path to the path environment variable of the specified scope. The path must exist. Also, if the paths overlap, they will not be added.

  .EXAMPLE
  PS C:\>Add-WUEnvPath -Path $env:USERPROFILE

  In this example, add $env:USERPROFILE to the process scope path environment variable.

  .LINK
  Remove-WUEnvPath
#>

[CmdletBinding(SupportsShouldProcess,
  DefaultParameterSetName = 'Path')]
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

  # Specifies the location where an environment variable. The default Scope is Process.
  [ValidateSet('LocalMachine', 'CurrentUser', 'Process')]
  [string[]]
  $Scope = 'Process'
)

Set-StrictMode -Version 'Latest'

$paths = @()
if ($psCmdlet.ParameterSetName -eq 'Path') {
  foreach ($aPath in $Path) {
    if (!(Test-Path -Path $aPath -PathType Container)) {
      $ex = New-Object System.Management.Automation.ItemNotFoundException "Cannot find directory path '$aPath' because it does not exist."
      $category = [System.Management.Automation.ErrorCategory]::ObjectNotFound
      $errRecord = New-Object System.Management.Automation.ErrorRecord $ex, 'PathNotFound', $category, $aPath
      $psCmdlet.WriteError($errRecord)
      continue
    }

    # Resolve any wildcards that might be in the path
    $provider = $null
    $paths += $psCmdlet.SessionState.Path.GetResolvedProviderPathFromPSPath($aPath, [ref]$provider)
  }
}
else {
  foreach ($aPath in $LiteralPath) {
    if (!(Test-Path -LiteralPath $aPath -PathType Container)) {
      $ex = New-Object System.Management.Automation.ItemNotFoundException "Cannot find directory path '$aPath' because it does not exist."
      $category = [System.Management.Automation.ErrorCategory]::ObjectNotFound
      $errRecord = New-Object System.Management.Automation.ErrorRecord $ex, 'PathNotFound', $category, $aPath
      $psCmdlet.WriteError($errRecord)
      continue
    }

    # Resolve any relative paths
    $paths += $psCmdlet.SessionState.Path.GetUnresolvedProviderPathFromPSPath($aPath)
  }
}

if (!$paths) {
  return
}

$Scope = $Scope + 'Process' | Select-Object -Unique

$scopeParams = @{
  LocalMachine = 'ForComputer'
  CurrentUser  = 'ForUser'
  Process      = 'ForProcess'
}
$scopeTargets = @{
  LocalMachine = 'Machine'
  CurrentUser  = 'User'
  Process      = 'Process'
}

foreach ($aScope in $Scope) {
  [string[]]$currentEnvPaths = [System.Environment]::GetEnvironmentVariable('Path', $scopeTargets.$aScope) -split ';'
  $newEnvPath = ($currentEnvPaths + $paths | Where-Object { $_ } | Select-Object -Unique) -join ';'

  if ($pscmdlet.ShouldProcess($newEnvPath, "Set to the Path environment variable for $aScope")) {
    $setEnvArgs = @{
      Name                 = 'Path'
      Value                = $newEnvPath
      $scopeParams.$aScope = $true
    }
    Set-CEnvironmentVariable @setEnvArgs
  }
}
