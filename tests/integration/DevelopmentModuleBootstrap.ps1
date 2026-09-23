[CmdletBinding()]
param()

Set-StrictMode -Version 2.0
$ErrorActionPreference = 'Stop'

if ($env:CI -ne 'true') {
    throw 'This integration test is intended to run only in CI.'
}

$repositoryRoot = Split-Path -Path (Split-Path -Path $PSScriptRoot -Parent) -Parent
$installScriptPath = Join-Path -Path $repositoryRoot -ChildPath 'install.ps1'
$requirementsPath = Join-Path -Path $repositoryRoot -ChildPath 'build.requirements.psd1'
$requirements = Import-PowerShellDataFile -Path $requirementsPath
$requiredPowerShellGetVersion = [version]'2.2.5'

Import-Module -Name 'PowerShellGet' -MaximumVersion $requiredPowerShellGetVersion -ErrorAction Stop
if (Get-PSRepository -Name 'PSGallery' -ErrorAction Ignore) {
    Unregister-PSRepository -Name 'PSGallery' -ErrorAction Stop
}

$olderPowerShellGet = Get-Module -Name 'PowerShellGet' -ListAvailable |
    Where-Object { $_.Version -lt $requiredPowerShellGetVersion } |
    Sort-Object -Property Version -Descending |
    Select-Object -First 1
$packageManagement = Get-Module -Name 'PackageManagement' -ListAvailable |
    Sort-Object -Property Version -Descending |
    Select-Object -First 1
if (-not $olderPowerShellGet -or -not $packageManagement) {
    throw 'The CI image must provide an older inbox PowerShellGet for the bootstrap test.'
}

$bootstrapModulePath = Join-Path -Path $env:RUNNER_TEMP -ChildPath 'PSWinUtil-bootstrap-modules'
foreach ($module in @($olderPowerShellGet, $packageManagement)) {
    $moduleDestination = Join-Path -Path (Join-Path -Path $bootstrapModulePath -ChildPath $module.Name) -ChildPath $module.Version.ToString()
    New-Item -Path (Split-Path -Path $moduleDestination -Parent) -ItemType Directory -Force | Out-Null
    Copy-Item -LiteralPath $module.ModuleBase -Destination $moduleDestination -Recurse
}

$newerPowerShellGetRoots = @(
    Get-Module -Name 'PowerShellGet' -ListAvailable |
        Where-Object { $_.Version -ge $requiredPowerShellGetVersion } |
        ForEach-Object { Split-Path -Path (Split-Path -Path $_.ModuleBase -Parent) -Parent } |
        Select-Object -Unique
)
$modulePaths = @($bootstrapModulePath) + @(
    $env:PSModulePath -split [IO.Path]::PathSeparator |
        Where-Object { $_ -notin $newerPowerShellGetRoots }
)
$env:PSModulePath = $modulePaths -join [IO.Path]::PathSeparator
$availablePowerShellGet = Get-Module -Name 'PowerShellGet' -ListAvailable
if ($availablePowerShellGet | Where-Object { $_.Version -ge $requiredPowerShellGetVersion }) {
    throw 'The bootstrap test must hide PowerShellGet 2.2.5 and newer.'
}
if (-not ($availablePowerShellGet | Where-Object { $_.Version -lt $requiredPowerShellGetVersion })) {
    throw 'The bootstrap test must expose an older PowerShellGet version.'
}

$powerShellPath = Join-Path -Path $PSHOME -ChildPath 'powershell.exe'
& $powerShellPath -NoProfile -ExecutionPolicy Bypass -File $installScriptPath
if ($LASTEXITCODE -ne 0) {
    throw "The development module installation failed with exit code $LASTEXITCODE."
}

Import-Module -Name 'Microsoft.PowerShell.PSResourceGet' -RequiredVersion $requirements['Microsoft.PowerShell.PSResourceGet'] -Force -ErrorAction Stop
$psGallery = Get-PSResourceRepository -Name 'PSGallery' -ErrorAction Stop
if (-not $psGallery.Trusted) {
    throw 'PSGallery must be trusted after development module installation.'
}

foreach ($name in $requirements.Keys) {
    Import-Module -Name $name -RequiredVersion $requirements[$name] -ErrorAction Stop
}

Unregister-PSResourceRepository -Name 'PSGallery' -ErrorAction Stop
& $powerShellPath -NoProfile -ExecutionPolicy Bypass -File $installScriptPath | Out-Null
if ($LASTEXITCODE -ne 0) {
    throw "The repeated development module installation failed with exit code $LASTEXITCODE."
}

$psGallery = Get-PSResourceRepository -Name 'PSGallery' -ErrorAction Stop
if (-not $psGallery.Trusted) {
    throw 'PSGallery must be trusted after repeated development module installation.'
}

foreach ($name in $requirements.Keys) {
    Import-Module -Name $name -RequiredVersion $requirements[$name] -ErrorAction Stop
}
