$PSWinUtil = Convert-Path $PSScriptRoot

# Private functions
function Get-WURegistryHash {
    $registryFileName = (Get-Variable MyInvocation -Scope 1).Value.MyCommand.Name -replace '.+-WU', ''
    return . "$PSWinUtil/resources/registry/$registryFileName"
}

function Test-WUAdmin {
    (
        [Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::
        GetCurrent()
    ).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
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
            $keyPath = Resolve-WUFullPath -Keyname $hash.$aScope.Keyname
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
        CmdName = 'Set-CRegistryKeyValue'
        AppName = 'yuusakuri/carbon'
    }
)
$chocoDepends = @(
    @{
        CmdName = 'es.exe'
        AppName = 'Everything'
    }
)

[hashtable[]]$installScoopDepends = $scoopDepends | Where-Object { !(Get-Command -Name $_.CmdName -ErrorAction Ignore) }
if ($installScoopDepends) {
    if (!(Get-Command -Name scoop -ErrorAction Ignore)) {
        # Install scoop
        Invoke-WebRequest -useb get.scoop.sh | Invoke-Expression
    }
    if (!(Get-Command -Name git -ErrorAction Ignore)) {
        # Install git
        scoop install git --force
    }
    . {
        # Add buckets
        scoop bucket add extras
        scoop bucket add yuusakuri https://github.com/yuusakuri/scoop-bucket.git
    } 6>&1 | Out-Null

    foreach ($aInstallDepend in $installScoopDepends) {
        Write-Host ("Installing '{0}'" -f $aInstallDepend.AppName)
        scoop install $aInstallDepend.AppName --force
        if (!(Get-Command -Name $aInstallDepend.CmdName -ErrorAction Ignore)) {
            Write-Warning ("Unable to resolve PSWinUtil Dependencies. Installation of '{0}' failed." -f $aInstallDepend.AppName)
        }
    }
}

[hashtable[]]$installChocoDepends = $chocoDepends | Where-Object { !(Get-Command -Name $_.CmdName -ErrorAction Ignore) }
if ($installChocoDepends) {
    if (!(Test-WUAdmin)) {
        Write-Warning 'Unable to resolve PSWinUtil Dependencies. Chocolatey require admin rights.'
    }
    else {
        if (!(Get-Command -Name chocolatey -ErrorAction Ignore)) {
            # 関数名の衝突を避ける
            $PSModuleAutoloadingPreference = 'ModuleQualified'
            $moduleNames = @(
                'Carbon'
            )
            Remove-Module $moduleNames -ErrorAction Ignore

            # Install Chocolatey
            Invoke-WebRequest https://chocolatey.org/install.ps1 -UseBasicParsing | Invoke-Expression
            # スクリプト実行の確認をしない
            choco feature enable -n allowGlobalConfirmation
            # チェックサムを無効にする
            choco feature disable -n checksumFiles

            $PSModuleAutoloadingPreference = $null
        }

        foreach ($aInstallDepend in $installChocoDepends) {
            Write-Host ("Installing '{0}'" -f $aInstallDepend.AppName)
            choco install $aInstallDepend.AppName -y --force --ignore-checksums -limitoutput
            if (!(Get-Command -Name $aInstallDepend.CmdName -ErrorAction Ignore)) {
                Write-Warning ("Unable to resolve PSWinUtil Dependencies. Installation of '{0}' failed." -f $aInstallDepend.AppName)
            }
        }
    }
}

# Pass the path to the required executable.
Add-WUEnvPath -LiteralPath (Get-ChildItem -LiteralPath "$PSWinUtil\tools" -Directory).FullName -Scope Process

# Load AngleSharp
Add-AngleSharp
