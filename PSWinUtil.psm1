$env:PSWinUtil = Convert-Path $PSScriptRoot

# Private functions
function Get-WURegistryHash {
  $registryFileName = (Get-Variable MyInvocation -Scope 1).Value.MyCommand.Name -replace '.+-WU', ''
  return . "$env:PSWinUtil/resources/registry/$registryFileName"
}

function Set-WURegistryFromHash {
  [CmdletBinding(SupportsShouldProcess)]
  param (
    [Parameter(Mandatory,
      Position = 0,
      ParameterSetName = 'LiteralPath',
      ValueFromPipelineByPropertyName)]
    [ValidateNotNullOrEmpty()]
    [hashtable]
    $RegistryHash,

    [string[]]
    $Scope,

    [string]
    $DataKey
  )

  $dataTypeParamNames = @{
    REG_SZ       = 'String'
    REG_BINARY   = 'Binary'
    REG_DWORD    = 'DWord'
    REG_QWORD    = 'QWord'
    REG_MULTI_SZ = 'Strings'
  }

  foreach ($hashKey in $RegistryHash.keys) {
    $hash = $RegistryHash.$hashKey

    if (!$Scope) {
      [string[]]$Scope = $hash.keys
    }

    foreach ($aScope in $Scope) {
      if ($DataKey -and $hash.$aScope.Data.GetType().Name -eq 'Hashtable') {
        $data = $hash.$aScope.Data.$dataKey
      }
      else {
        $data = $hash.$aScope.Data
      }
      $keyPath = Resolve-WUFullPath -KeyName $hash.$aScope.KeyName
      $valueName = $hash.$aScope.ValueName
      $dataType = $hash.$aScope.Type

      $registryCmdParam = @{}
      $registryCmdParam.Add('Path', $keyPath)
      $registryCmdParam.Add('Name', $valueName)
      $registryCmdParam.Add($dataTypeParamNames.$dataType, $data)

      if ($psCmdlet.ShouldProcess("Path: $keyPath ValueName: $valueName Value: $data", 'Set to registry')) {
        Set-CRegistryKeyValue @registryCmdParam
      }
    }
  }
}

# Public functions
$functions = Get-ChildItem -Path ('{0}\functions' -f $env:PSWinUtil) -Recurse -File
foreach ($function in $functions) {
  New-Item -Path ('function:\{0}' -f $function.BaseName) -Value (Get-Content -Path $function.FullName -Raw)
}

# Pass the path to the required executable
Add-WUEnvPath -LiteralPath (Get-ChildItem -LiteralPath "$env:PSWinUtil\tools" -Directory).FullName -Scope Process

# Resolve dependencies using scoop which does not require administrator privileges
$scoopDepends = @(
  @{
    CmdName = 'aria2c.exe'
    AppName = 'main/aria2'
  }
  @{
    CmdName = 'ffprobe.exe'
    AppName = 'main/ffmpeg'
  }
  @{
    CmdName = 'es.exe'
    AppName = 'extras/everything'
  }
  @{
    CmdName = 'Set-CRegistryKeyValue'
    AppName = 'yuusakuri/carbon'
  }
)

$installScoopDepends = $scoopDepends | Where-Object { !(Get-Command -Name $_.CmdName -ErrorAction Ignore) }
if ($installScoopDepends) {
  if (!(Get-Command -Name scoop -ErrorAction Ignore)) {
    # Install scoop
    Invoke-WebRequest -useb get.scoop.sh | Invoke-Expression
  }
  if (!(Get-Command -Name git -ErrorAction Ignore)) {
    # Install git
    scoop install git
  }
  . {
    # Add buckets
    scoop bucket add extras
    scoop bucket add yuusakuri https://github.com/yuusakuri/scoop-bucket.git
  } 6>&1 | Out-Null

  foreach ($installScoopDepend in $installScoopDepends) {
    scoop install $installScoopDepend.AppName
  }
}
