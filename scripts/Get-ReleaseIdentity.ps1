[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [string]$Branch,

    [Parameter()]
    [ValidateNotNullOrEmpty()]
    [string]$ManifestPath = (Join-Path -Path $PSScriptRoot -ChildPath '../src/PSWinUtil/PSWinUtil.psd1'),

    [Parameter()]
    [AllowEmptyCollection()]
    [string[]]$ExistingTagName = @()
)

Set-StrictMode -Version 2.0
$ErrorActionPreference = 'Stop'

$branchPattern = '^release/(?<Version>(0|[1-9][0-9]*)\.(0|[1-9][0-9]*)\.(0|[1-9][0-9]*))$'
if ($Branch -notmatch $branchPattern) {
    throw "Invalid release branch: $Branch"
}

$version = $Matches['Version']
$tagName = "v$version"

$resolvedManifestPath = (Resolve-Path -LiteralPath $ManifestPath -ErrorAction Stop).Path
$manifest = Import-PowerShellDataFile -LiteralPath $resolvedManifestPath
if (-not $manifest.ContainsKey('ModuleVersion')) {
    throw "The module manifest does not define ModuleVersion: $resolvedManifestPath"
}

$manifestVersion = [string]$manifest.ModuleVersion
if ($manifestVersion -ne $version) {
    throw "Release branch version $version does not match ModuleVersion $manifestVersion."
}

$releasedVersions = @(
    foreach ($existingTag in $ExistingTagName) {
        if ($existingTag -match '^v(?<Version>[0-9]+\.[0-9]+\.[0-9]+)$') {
            [version]$Matches['Version']
        }
    }
)
$latestReleasedVersion = $releasedVersions |
    Sort-Object -Descending |
    Select-Object -First 1
if ($null -ne $latestReleasedVersion -and [version]$version -lt $latestReleasedVersion) {
    throw "Release version $version is older than existing tag v$latestReleasedVersion."
}

[pscustomobject]@{
    Version = $version
    TagName = $tagName
    ManifestPath = $resolvedManifestPath
}
