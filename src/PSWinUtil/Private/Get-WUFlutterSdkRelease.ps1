function Get-WUFlutterSdkRelease {
    <#
    .SYNOPSIS
    Gets Flutter SDK release metadata for Windows.

    .DESCRIPTION
    Reads the official Flutter release index and returns metadata for one Windows SDK archive. Releases without architecture metadata are treated as x64 for compatibility with older index entries.

    .PARAMETER Version
    Specifies a Flutter SDK version. An empty value selects the current release for the requested channel.

    .PARAMETER Channel
    Specifies the stable or beta release channel.

    .PARAMETER Architecture
    Specifies the x64 or arm64 SDK architecture.

    .EXAMPLE
    Get-WUFlutterSdkRelease -Version '3.47.1' -Channel 'stable' -Architecture 'x64'

    Returns validated metadata for Flutter SDK 3.47.1.

    .INPUTS
    None

    .OUTPUTS
    System.Management.Automation.PSCustomObject
    #>
    [CmdletBinding()]
    [OutputType([pscustomobject])]
    param(
        [Parameter()]
        [AllowEmptyString()]
        [string]$Version,

        [Parameter(Mandatory = $true)]
        [ValidateSet('stable', 'beta')]
        [string]$Channel,

        [Parameter(Mandatory = $true)]
        [ValidateSet('x64', 'arm64')]
        [string]$Architecture
    )

    $releaseIndexUri = 'https://storage.googleapis.com/flutter_infra_release/releases/releases_windows.json'
    $progressPreference = 'SilentlyContinue'
    try {
        $response = Invoke-WebRequest -UseBasicParsing -Uri $releaseIndexUri -ErrorAction Stop
        $releaseData = $response.Content | ConvertFrom-Json -ErrorAction Stop
    } catch {
        throw "Could not read the Flutter SDK release index. $($_.Exception.Message)"
    }

    $baseUrl = [string]$releaseData.base_url
    $baseUri = $null
    if (
        [string]::IsNullOrWhiteSpace($baseUrl) -or
        -not [uri]::TryCreate("$($baseUrl.TrimEnd('/'))/", [UriKind]::Absolute, [ref]$baseUri) -or
        $baseUri.Scheme -ne 'https'
    ) {
        throw 'The Flutter SDK release index contains an invalid base URL.'
    }

    $matchingReleases = @(
        $releaseData.releases |
            Where-Object {
                $releaseArchitecture = [string]$_.arch
                if ([string]::IsNullOrWhiteSpace($releaseArchitecture)) {
                    $releaseArchitecture = [string]$_.dart_sdk_arch
                }
                if ([string]::IsNullOrWhiteSpace($releaseArchitecture)) {
                    $releaseArchitecture = 'x64'
                }

                $_.channel -eq $Channel -and
                $releaseArchitecture -eq $Architecture -and
                (
                    [string]::IsNullOrWhiteSpace($Version) -or
                    $_.version -eq $Version
                )
            }
    )

    $targetRelease = $null
    if ([string]::IsNullOrWhiteSpace($Version)) {
        $currentReleaseHash = [string]$releaseData.current_release.$Channel
        if (-not [string]::IsNullOrWhiteSpace($currentReleaseHash)) {
            $targetRelease = @(
                $matchingReleases |
                    Where-Object { $_.hash -eq $currentReleaseHash }
            )[0]
        }
    }
    if ($null -eq $targetRelease) {
        $targetRelease = $matchingReleases | Select-Object -First 1
    }

    if ($null -eq $targetRelease) {
        $versionDescription = $Version
        if ([string]::IsNullOrWhiteSpace($versionDescription)) {
            $versionDescription = 'current'
        }
        throw "The $versionDescription Flutter SDK release was not found for channel '$Channel' and architecture '$Architecture'."
    }

    $archivePath = [string]$targetRelease.archive
    if ([string]::IsNullOrWhiteSpace($archivePath)) {
        throw 'The Flutter SDK release index does not contain an archive path.'
    }

    $archiveUri = $null
    if (
        -not [uri]::TryCreate($baseUri, $archivePath.TrimStart('/'), [ref]$archiveUri) -or
        $archiveUri.Scheme -ne 'https'
    ) {
        throw 'The Flutter SDK release index contains an invalid archive URL.'
    }

    [pscustomobject]@{
        Version = [string]$targetRelease.version
        Channel = [string]$targetRelease.channel
        Architecture = $Architecture
        Uri = $archiveUri
    }
}
