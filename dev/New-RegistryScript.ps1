[CmdletBinding(SupportsShouldProcess,
  DefaultParameterSetName = 'Path')]
param (
  # Specifies a path to one or more locations. Wildcards are permitted.
  [Parameter(Mandatory,
    Position = 0,
    ValueFromPipeline,
    ValueFromPipelineByPropertyName)]
  [ValidateNotNullOrEmpty()]
  [string]
  $Name,

  # Specifies a path to one or more locations. Unlike the Path parameter, the value of the LiteralPath parameter is used exactly as it is typed. No characters are interpreted as wildcards. If the path includes escape characters, enclose it in single quotation marks. Single quotation marks tell Windows PowerShell not to interpret any characters as escape sequences.
  [ValidateNotNullOrEmpty()]
  [ValidateSet('Enable', 'Disable', 'Set', 'Switch', 'Register', 'New', 'Add', 'Remove')]
  [string[]]
  $Verb = @('Enable', 'Disable'),

  [switch]
  $NoScope
)

$Name = ConvertTo-WUPascalCase -String $Name
$registryFiles = @()
$registryFiles += @{}
$registryFiles[0].Path = "$env:PSWinUtil/resources/registry/$Name.ps1"
$registryFiles[0].Content = @"
@{
  $Name = @{
    Machine = @{
      KeyName   = ''
      ValueName = ''
      Type      = 'REG_DWORD'
      Data      = @{
        Enable  = 1
        Disable = 0
      }
  }
  User = @{
      KeyName   = ''
      ValueName = ''
      Type      = 'REG_SZ'
      Data      = @{
        Enable  = 1
        Disable = 0
      }
    }
  }
}
"@

for ($i = 0; $i -lt $Verb.Count; $i++) {
  $registryFiles += @{}
  $registryFiles[$i + 1].Path = "$env:PSWinUtil/functions/registry/{0}-WU$Name.ps1" -f $Verb[$i]
  $scopeParamStr = @'
  # Specify the target user. The target is the current user if you specify 'User', and all users if you specify 'Machine'. The default value is 'User'.
  [ValidateSet('User', 'Machine')]
  [string]
  $Scope = 'User'

'@
  $scopeArgStr = ' -Scope $Scope'

  if ($NoScope) {
    $scopeParamStr = ''
    $scopeArgStr = ''
  }
  $registryFiles[$i + 1].Content = @"
<#
  .DESCRIPTION
  This cmdlet works with registry.
#>

[CmdletBinding(SupportsShouldProcess)]
param (
$scopeParamStr)

Set-StrictMode -Version 'Latest'
`$registryHash = Get-WURegistryHash
if (!`$registryHash) {
  return
}

Set-WURegistryFromHash -RegistryHash `$registryHash$scopeArgStr -DataKey `$MyInvocation.MyCommand.Verb
"@
}

foreach ($registryFile in $registryFiles) {
  $aPath = $registryFile.Path
  $aContent = $registryFile.Content
  if ((Test-Path -LiteralPath $aPath)) {
    Write-Error "Path '$aPath' already exists."
    continue
  }

  [System.IO.File]::WriteAllLines($aPath, $aContent, (New-Object System.Text.UTF8Encoding $true))
}
