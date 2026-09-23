[CmdletBinding()]
param()

Set-StrictMode -Version 2.0
$ErrorActionPreference = 'Stop'

$requirementsPath = Join-Path -Path $PSScriptRoot -ChildPath 'build.requirements.psd1'
if (-not (Test-Path -LiteralPath $requirementsPath -PathType Leaf)) {
    throw "Development module requirements were not found: $requirementsPath"
}

$requirements = Import-PowerShellDataFile -Path $requirementsPath
if (-not $requirements.ContainsKey('Microsoft.PowerShell.PSResourceGet')) {
    throw 'A required development module is not pinned: Microsoft.PowerShell.PSResourceGet'
}

[Net.ServicePointManager]::SecurityProtocol =
[Net.ServicePointManager]::SecurityProtocol -bor [Net.SecurityProtocolType]::Tls12

function Install-PowerShellGet {
    param(
        [Parameter(Mandatory)]
        [string]$Version
    )

    $availablePowerShellGet = Get-Module -Name 'PowerShellGet' -ListAvailable |
        Where-Object { $_.Version -eq [version]$Version }

    if ($availablePowerShellGet) {
        Import-Module -Name 'PowerShellGet' -RequiredVersion $Version -Force -ErrorAction Stop
    } else {
        # Use the inbox or an installed 2.x module to bootstrap the pinned release.
        Import-Module -Name 'PowerShellGet' -MaximumVersion $Version -Force -ErrorAction Stop
    }

    if ($null -eq (Get-PSRepository -Name 'PSGallery' -ErrorAction Ignore)) {
        Register-PSRepository -Default -InstallationPolicy 'Trusted' -ErrorAction Stop
    } else {
        Set-PSRepository -Name 'PSGallery' -InstallationPolicy 'Trusted' -ErrorAction Stop
    }

    Install-PackageProvider -Name 'NuGet' -Scope 'CurrentUser' -Force -ErrorAction Stop | Out-Null

    if (-not $availablePowerShellGet) {
        PowerShellGet\Install-Module -Name 'PowerShellGet' -RequiredVersion $Version -Repository 'PSGallery' -Scope 'CurrentUser' -Force -AllowClobber -ErrorAction Stop
        Import-Module -Name 'PowerShellGet' -RequiredVersion $Version -Force -ErrorAction Stop
    }
}

function Install-PSResourceGet {
    param(
        [Parameter(Mandatory)]
        [string]$Version
    )

    Write-Verbose ("PSModulePath: {0}" -f $env:PSModulePath)
    $availablePSResourceGet = Get-Module -Name 'Microsoft.PowerShell.PSResourceGet' -ListAvailable |
        Where-Object { $_.Version -eq [version]$Version }

    if ($availablePSResourceGet) {
        return
    }

    Install-PowerShellGet -Version '2.2.5'
    PowerShellGet\Install-Module -Name 'Microsoft.PowerShell.PSResourceGet' -RequiredVersion $Version -Repository 'PSGallery' -Scope 'CurrentUser' -Force -AllowClobber -ErrorAction Stop
}

function Install-DevelopmentDependency {
    param(
        [Parameter(Mandatory)]
        [hashtable]$Requirements
    )

    foreach ($moduleName in $Requirements.Keys) {
        if ($moduleName -eq 'Microsoft.PowerShell.PSResourceGet') {
            continue
        }

        Install-PSResource -Name $moduleName -Version $Requirements[$moduleName] -Scope 'CurrentUser' -TrustRepository -Quiet -ErrorAction Stop
    }
}

Install-PSResourceGet -Version $requirements['Microsoft.PowerShell.PSResourceGet']

$availablePSResourceGet = Get-Module -Name 'Microsoft.PowerShell.PSResourceGet' -ListAvailable |
    Where-Object { $_.Version -eq [version]$requirements['Microsoft.PowerShell.PSResourceGet'] }
foreach ($module in Get-Module -Name 'Microsoft.PowerShell.PSResourceGet' -ListAvailable) {
    Write-Verbose ("Detected {0} {1}: {2}" -f $module.Name, $module.Version, $module.ModuleBase)
}
if (-not $availablePSResourceGet) {
    throw "Required module Microsoft.PowerShell.PSResourceGet $($requirements['Microsoft.PowerShell.PSResourceGet']) was not found. PSModulePath: $env:PSModulePath"
}

Import-Module -Name 'Microsoft.PowerShell.PSResourceGet' -RequiredVersion $requirements['Microsoft.PowerShell.PSResourceGet'] -Force -ErrorAction Stop
Install-DevelopmentDependency -Requirements $requirements
