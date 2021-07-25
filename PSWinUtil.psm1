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

function Convert-StringToBool {
    [CmdletBinding()]
    param (
        # Specifies a path to one or more locations. Wildcards are permitted.
        [Parameter(Position = 0,
            ValueFromPipeline,
            ValueFromPipelineByPropertyName)]
        [string]
        $String
    )
    $trueStrings = @(
        'yes'
        'y'
        'true'
    )
    $falseStrings = @(
        'no'
        'n'
        'false'
    )

    if ($String -in $trueStrings) {
        return $true
    }
    if ($String -in $falseStrings) {
        return $false
    }
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

function Get-WUAvailableDotnet {
    [CmdletBinding()]
    param (
    )

    $availableDotnets = @()

    $availableDotnets += [PSCustomObject]@{
        'name'    = '.NETCoreApp'
        'version' = . {
            if ((Get-Command -Name 'dotnet' -ErrorAction Ignore)) {
                # .NET Core or .NET 5+ is installed.
                dotnet --list-runtimes |
                Where-Object { $_ -clike 'Microsoft.NETCore.App*' } |
                ForEach-Object {
                    [regex]::Matches(($_ -replace '^Microsoft.NETCore.App '), '^[\d.]+') |
                    Where-Object { $_ } |
                    Select-Object -ExpandProperty Value
                } |
                Sort-Object { [System.Version]$_ } |
                Select-Object -Last 1
            }
            else {
                $null
            }
        }
    }

    $availableDotnets += [PSCustomObject]@{
        'name'    = '.NETFramework'
        'version' = . {
            dotnetversions -b |
            ForEach-Object {
                [regex]::Matches($_, '^[\d.]+') |
                Where-Object { $_ } |
                Select-Object -ExpandProperty Value
            } |
            Sort-Object { [System.Version]$_ } |
            Select-Object -Last 1
        }
    }

    $availableDotnets += [PSCustomObject]@{
        'name'    = '.NETStandard'
        'version' = . {
            $dotnetStandardVersions = @(
                [PSCustomObject]@{
                    '.NETStandard'  = '1.0'
                    '.NETCoreApp'   = '1.0'
                    '.NETFramework' = '4.5'
                }
                [PSCustomObject]@{
                    '.NETStandard'  = '1.1'
                    '.NETCoreApp'   = '1.0'
                    '.NETFramework' = '4.5'
                }
                [PSCustomObject]@{
                    '.NETStandard'  = '1.2'
                    '.NETCoreApp'   = '1.0'
                    '.NETFramework' = '4.5.1'
                }
                [PSCustomObject]@{
                    '.NETStandard'  = '1.3'
                    '.NETCoreApp'   = '1.0'
                    '.NETFramework' = '4.6'
                }
                [PSCustomObject]@{
                    '.NETStandard'  = '1.4'
                    '.NETCoreApp'   = '1.0'
                    '.NETFramework' = '4.6.1'
                }
                [PSCustomObject]@{
                    '.NETStandard'  = '1.5'
                    '.NETCoreApp'   = '1.0'
                    '.NETFramework' = '4.6.11'
                }
                [PSCustomObject]@{
                    '.NETStandard'  = '1.6'
                    '.NETCoreApp'   = '1.0'
                    '.NETFramework' = '4.6.11'
                }
                [PSCustomObject]@{
                    '.NETStandard'  = '2.0'
                    '.NETCoreApp'   = '2.0'
                    '.NETFramework' = '4.6.11'
                }
                [PSCustomObject]@{
                    '.NETStandard'  = '2.1'
                    '.NETCoreApp'   = '3.0'
                    '.NETFramework' = $null
                }
            )

            $availableDotnets |
            Where-Object { $_.version } |
            Select-Object -First 1 |
            ForEach-Object {
                $aAvailableDotnet = $_
                $dotnetStandardVersions |
                Where-Object { $null -ne $_.($aAvailableDotnet.name) } |
                Where-Object { [System.Version]$_.($aAvailableDotnet.name) -le [System.Version]$aAvailableDotnet.version } |
                Select-Object -Last 1
            } |
            Select-Object -ExpandProperty '.NETStandard'
        }
    }

    return $availableDotnets
}

# Public functions
$functionScripts = Get-ChildItem -LiteralPath $PSWinUtilFunctionDir -Recurse -File
foreach ($aFunctionScript in $functionScripts) {
    . $aFunctionScript.FullName
    Set-Alias -Name $aFunctionScript.BaseName -Value ($aFunctionScript.BaseName -replace '-', '-WU')
}

# Make NuGet package install directory
if (!$env:NUGET_PACKAGE_DIR) {
    $env:NUGET_PACKAGE_DIR = $env:USERPROFILE |
    Join-Path -ChildPath 'NuGet\packages'
}
if (!(Test-WUPathProperty -LiteralPath $env:NUGET_PACKAGE_DIR -PSProvider FileSystem -PathType Container)) {
    New-Item -Path $env:NUGET_PACKAGE_DIR -ItemType 'Directory' -Force | Out-String | Write-Verbose
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
    @{
        CmdName = 'dotnetversions.exe'
        AppName = 'yuusakuri/dotnetversions'
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
    Unsafe   = $true
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
Add-WUPathEnvironmentVariable -LiteralPath (Get-ChildItem -LiteralPath "$PSWinUtil\tools" -Directory).FullName -Scope Process
