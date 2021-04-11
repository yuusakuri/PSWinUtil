$PSWinUtil = Convert-Path $PSScriptRoot
$PSWinUtilBinDir = $PSWinUtil | Join-Path -ChildPath 'bin'

# Private functions
function Test-WUAdmin {
    (
        [Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::
        GetCurrent()
    ).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

function Get-WURegistryHash {
    $registryFileName = (Get-Variable MyInvocation -Scope 1).Value.MyCommand.Name -replace '.+-WU', ''
    return . "$PSWinUtil/resources/registry/$registryFileName"
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
$functions = Get-ChildItem -Path ('{0}\functions' -f $PSWinUtil) -Recurse -File
foreach ($function in $functions) {
    New-Item -Path ('function:\{0}' -f $function.BaseName) -Value (Get-Content -Path $function.FullName -Raw)
}

# Alias
Set-Alias -Name 'Install-WUApp' -Value (Join-Path $PSWinUtilBinDir 'Install-App.ps1')

# Resolve dependencies using scoop which does not require administrator privileges
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
    ChocoApp = $chocoDepends.AppName
    Force    = $true
}
if ($scoopDepends) {
    $installWuAppArgs += @{
        ScoopBucket = $scoopBuckets
        ScoopApp    = $scoopDepends.AppName
    }
}
Install-WUApp @installWuAppArgs

# Pass the path to the required executable.
Add-WUEnvPath -LiteralPath (Get-ChildItem -LiteralPath "$PSWinUtil\tools" -Directory).FullName -Scope Process

# Load assembly
Add-WUAngleSharp
