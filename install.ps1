[CmdletBinding()]
param()

Set-StrictMode -Version 2.0
$ErrorActionPreference = 'Stop'

$requirementsPath = Join-Path -Path $PSScriptRoot -ChildPath 'build.requirements.psd1'
if (-not (Test-Path -LiteralPath $requirementsPath -PathType Leaf)) {
    throw "Development module requirements were not found: $requirementsPath"
}

$requirements = Import-PowerShellDataFile -Path $requirementsPath
$psResourceGetName = 'Microsoft.PowerShell.PSResourceGet'
if (-not $requirements.ContainsKey($psResourceGetName)) {
    throw "A required development module is not pinned: $psResourceGetName"
}

$psResourceGetVersion = [string]$requirements[$psResourceGetName]
[Net.ServicePointManager]::SecurityProtocol =
[Net.ServicePointManager]::SecurityProtocol -bor [Net.SecurityProtocolType]::Tls12

Write-Verbose ("PSModulePath: {0}" -f $env:PSModulePath)
$psResourceGetSpecification = @{
    ModuleName = $psResourceGetName
    RequiredVersion = $psResourceGetVersion
}
$requiredPSResourceGet = Get-Module -FullyQualifiedName $psResourceGetSpecification -ListAvailable
if (-not $requiredPSResourceGet) {
    $powerShellGetVersion = '2.2.5'
    $powerShellGetSpecification = @{
        ModuleName = 'PowerShellGet'
        RequiredVersion = $powerShellGetVersion
    }
    $requiredPowerShellGet = Get-Module -FullyQualifiedName $powerShellGetSpecification -ListAvailable
    if (-not $requiredPowerShellGet) {
        # Use the inbox or an installed 2.x module to bootstrap the pinned release.
        Import-Module -Name 'PowerShellGet' -MaximumVersion $powerShellGetVersion -Force -ErrorAction Stop
    } else {
        Import-Module -FullyQualifiedName $powerShellGetSpecification -Force -ErrorAction Stop
    }
    if ($null -eq (Get-PSRepository -Name 'PSGallery' -ErrorAction Ignore)) {
        Register-PSRepository -Default -InstallationPolicy 'Trusted' -ErrorAction Stop
    } else {
        Set-PSRepository -Name 'PSGallery' -InstallationPolicy 'Trusted' -ErrorAction Stop
    }
    Install-PackageProvider -Name 'NuGet' -Scope 'CurrentUser' -Force -ErrorAction Stop | Out-Null
    if (-not $requiredPowerShellGet) {
        PowerShellGet\Install-Module -Name 'PowerShellGet' -RequiredVersion $powerShellGetVersion -Repository 'PSGallery' -Scope 'CurrentUser' -Force -AllowClobber -ErrorAction Stop
        Import-Module -FullyQualifiedName $powerShellGetSpecification -Force -ErrorAction Stop
    }
    PowerShellGet\Install-Module -Name $psResourceGetName -Repository 'PSGallery' -RequiredVersion $psResourceGetVersion -Scope 'CurrentUser' -Force -AllowClobber -ErrorAction Stop
    $requiredPSResourceGet = Get-Module -FullyQualifiedName $psResourceGetSpecification -ListAvailable
}
foreach ($module in Get-Module -Name $psResourceGetName -ListAvailable) {
    Write-Verbose ("Detected {0} {1}: {2}" -f $module.Name, $module.Version, $module.ModuleBase)
}
if (-not $requiredPSResourceGet) {
    throw "Required module $psResourceGetName $psResourceGetVersion was not found. PSModulePath: $env:PSModulePath"
}

Import-Module -Name $psResourceGetName -RequiredVersion $psResourceGetVersion -Force -ErrorAction Stop

foreach ($moduleName in $requirements.Keys) {
    if ($moduleName -eq $psResourceGetName) {
        continue
    }

    Install-PSResource -Name $moduleName -Version $requirements[$moduleName] -Scope 'CurrentUser' -TrustRepository -Quiet -ErrorAction Stop
}
