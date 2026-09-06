[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [string]$TagName,

    [Parameter(Mandatory = $true)]
    [string]$Version,

    [Parameter(Mandatory = $true)]
    [string]$ReleaseCommit,

    [Parameter()]
    [AllowEmptyString()]
    [string]$TagCommit = '',

    [switch]$GalleryExists,

    [switch]$GitHubReleaseExists
)

Set-StrictMode -Version 2.0
$ErrorActionPreference = 'Stop'

$tagExists = -not [string]::IsNullOrWhiteSpace($TagCommit)
if ($tagExists -and $TagCommit -ne $ReleaseCommit) {
    throw "Tag $TagName does not point to release commit $ReleaseCommit."
}

if ($GalleryExists -and -not $tagExists) {
    throw "PowerShell Gallery version $Version exists without tag $TagName."
}

if ($GitHubReleaseExists -and (-not $tagExists -or -not $GalleryExists)) {
    throw "GitHub Release $TagName exists before its tag and Gallery publication are complete."
}

[pscustomobject]@{
    TagExists = $tagExists
    GalleryExists = [bool]$GalleryExists
    GitHubReleaseExists = [bool]$GitHubReleaseExists
}
