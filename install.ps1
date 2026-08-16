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

Install-PackageProvider -Name 'NuGet' -Scope 'CurrentUser' -Force | Out-Null
Install-Module -Name 'PowerShellGet' -Repository 'PSGallery' -Scope 'CurrentUser' -Force -AllowClobber
Install-Module -Name $psResourceGetName -Repository 'PSGallery' -RequiredVersion $psResourceGetVersion -Scope 'CurrentUser' -Force -AllowClobber
Import-Module -Name $psResourceGetName -RequiredVersion $psResourceGetVersion -Force

foreach ($moduleName in $requirements.Keys) {
    if ($moduleName -eq $psResourceGetName) {
        continue
    }

    Install-PSResource -Name $moduleName -Version $requirements[$moduleName] -Scope 'CurrentUser' -TrustRepository -Quiet
}
