$PSWinUtil = $PSScriptRoot
$PSWinUtilRegConfDir = $PSWinUtil | Join-Path -ChildPath "resources/registry"
$PSWinUtilFunctionDir = $PSWinUtil | Join-Path -ChildPath "functions"

# Private functions
function Test-WUAdmin {
    (
        [Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::
        GetCurrent()
    ).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

function Get-WURegistryHash {
    $registryFileName = (Get-Variable MyInvocation -Scope 1).Value.MyCommand.Name -creplace '.+-(WU)?', ''
    return . (Join-Path $PSWinUtilRegConfDir $registryFileName)
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
            $keyPath = ConvertTo-WUFullPath -Keyname $hash.$aScope.Keyname
            $valuename = $hash.$aScope.Valuename
            $dataType = $hash.$aScope.Type

            $registryCmdParam = @{}
            $registryCmdParam.Add('Path', $keyPath)
            $registryCmdParam.Add('Name', $valuename)
            $registryCmdParam.Add($dataTypeParamNames.$dataType, $data)

            if ($psCmdlet.ShouldProcess("Path: $keyPath Valuename: $valuename Value: $data", 'Set to registry')) {
                Set-CRegistryKeyValue @registryCmdParam
            }
        }
    }
}

# Public functions
$functionScripts = Get-ChildItem -LiteralPath $PSWinUtilFunctionDir -Recurse -File
foreach ($aFunctionScript in $functionScripts) {
    . $aFunctionScript.FullName
    Set-Alias -Name $aFunctionScript.BaseName -Value ($aFunctionScript.BaseName -replace '-', '-WU')
}

# Resolve dependencies
$scoopBuckets = @{
    'extras'    = ''
    'yuusakuri' = 'https://github.com/yuusakuri/scoop-bucket.git'
}
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
        CmdName = 'Set-CRegistryKeyValue'
        AppName = 'yuusakuri/carbon'
    }
) |
Where-Object { !(Get-Command -Name $_.CmdName -ErrorAction Ignore) }

$chocoDepends = @(
    @{
        CmdName = 'es.exe'
        AppName = 'Everything'
    }
) |
Where-Object { !(Get-Command -Name $_.CmdName -ErrorAction Ignore) }

$installWuAppArgs = @{
    Optimize = @()
    Force    = $true
}
if ($chocoDepends) {
    $installWuAppArgs += @{
        ChocolateyPackage = $chocoDepends.AppName
    }
    $installWuAppArgs.Optimize += 'Chocolatey'
}
if ($scoopDepends) {
    $installWuAppArgs += @{
        ScoopBucket = $scoopBuckets
        ScoopApp    = $scoopDepends.AppName
    }
    $installWuAppArgs.Optimize += 'Scoop'
}

if ($chocoDepends -or $scoopDepends) {
    Install-WUApp @installWuAppArgs
}

# Pass the path to the required executable.
Add-WUEnvPath -LiteralPath (Get-ChildItem -LiteralPath "$PSWinUtil\tools" -Directory).FullName -Scope Process

# Load assembly
Add-WUAngleSharp
