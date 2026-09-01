[CmdletBinding(SupportsShouldProcess = $true)]
param(
    [Parameter(Mandatory = $true)]
    [ValidatePattern('^(0|[1-9][0-9]*)\.(0|[1-9][0-9]*)\.(0|[1-9][0-9]*)$')]
    [string]$Version,

    [Parameter()]
    [ValidateNotNullOrEmpty()]
    [string]$ManifestPath = (Join-Path -Path $PSScriptRoot -ChildPath '../src/PSWinUtil/PSWinUtil.psd1')
)

Set-StrictMode -Version 2.0
$ErrorActionPreference = 'Stop'

$resolvedManifestPath = (Resolve-Path -LiteralPath $ManifestPath -ErrorAction Stop).Path
$manifest = Import-PowerShellDataFile -LiteralPath $resolvedManifestPath
if (-not $manifest.ContainsKey('ModuleVersion')) {
    throw "The module manifest does not define ModuleVersion: $resolvedManifestPath"
}

$currentVersion = [version][string]$manifest.ModuleVersion
$releaseVersion = [version]$Version
if ($releaseVersion -le $currentVersion) {
    throw "Release version $Version must be greater than the current version $currentVersion."
}

$manifestText = [System.IO.File]::ReadAllText($resolvedManifestPath)
$versionPattern = [regex]::new(
    "(?m)^(?<Prefix>[ `t]*ModuleVersion[ `t]*=[ `t]*)'(?<Version>[^']+)'(?<Suffix>[ `t]*)$"
)
$versionMatches = $versionPattern.Matches($manifestText)
if ($versionMatches.Count -ne 1) {
    throw "Expected exactly one single-quoted ModuleVersion entry: $resolvedManifestPath"
}

$updatedManifestText = $versionPattern.Replace(
    $manifestText,
    {
        param([System.Text.RegularExpressions.Match]$Match)

        $Match.Groups['Prefix'].Value + "'$Version'" + $Match.Groups['Suffix'].Value
    }
)

if ($PSCmdlet.ShouldProcess($resolvedManifestPath, "Set ModuleVersion to $Version")) {
    $utf8NoBom = [System.Text.UTF8Encoding]::new($false)
    [System.IO.File]::WriteAllText($resolvedManifestPath, $updatedManifestText, $utf8NoBom)
}

[pscustomobject]@{
    ManifestPath = $resolvedManifestPath
    PreviousVersion = $currentVersion.ToString()
    Version = $Version
}
