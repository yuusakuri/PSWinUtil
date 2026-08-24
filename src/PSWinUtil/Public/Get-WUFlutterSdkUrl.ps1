function Get-WUFlutterSdkUrl {
    <#
    .SYNOPSIS
    Gets a Flutter SDK download URL for Windows.

    .DESCRIPTION
    Reads the official Flutter release index and returns the download URL for a Windows Flutter SDK release. When Version is omitted, the current release for the selected channel and architecture is returned.

    .PARAMETER Version
    Specifies the Flutter SDK version. An omitted or empty value selects the current release for the requested channel.

    .PARAMETER Channel
    Specifies the stable or beta release channel. The default value is stable.

    .PARAMETER Architecture
    Specifies the x64 or arm64 SDK architecture. The default value is detected from the current Windows environment.

    .EXAMPLE
    Get-WUFlutterSdkUrl -Version '3.47.1'

    Returns the stable x64 Flutter SDK 3.47.1 download URL on an x64 computer.

    .EXAMPLE
    Get-WUFlutterSdkUrl -Channel 'beta' -Architecture 'x64'

    Returns the current beta x64 Flutter SDK download URL.

    .INPUTS
    System.String

    .OUTPUTS
    System.String
    #>
    [CmdletBinding()]
    [OutputType([string])]
    param(
        [Parameter(
            Position = 0,
            ValueFromPipeline = $true,
            ValueFromPipelineByPropertyName = $true
        )]
        [AllowEmptyString()]
        [string]$Version,

        [Parameter()]
        [ValidateSet('stable', 'beta')]
        [string]$Channel = 'stable',

        [Parameter()]
        [ValidateSet('x64', 'arm64')]
        [string]$Architecture = $(
            if (
                $env:PROCESSOR_ARCHITECTURE -eq 'ARM64' -or
                $env:PROCESSOR_ARCHITEW6432 -eq 'ARM64'
            ) {
                'arm64'
            } else {
                'x64'
            }
        )
    )

    process {
        $releaseParameters = @{
            Version = $Version
            Channel = $Channel
            Architecture = $Architecture
        }
        $release = Get-WUFlutterSdkRelease @releaseParameters
        $release.Uri.AbsoluteUri
    }
}
