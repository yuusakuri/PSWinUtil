function Install-WUAndroidPlatformTool {
    <#
    .SYNOPSIS
    Installs the Android Platform Tools package when it is missing or a version is requested.

    .DESCRIPTION
    Installs the Platform Tools package selected by the Android CLI in $env:ANDROID_HOME. An explicit version is installed even when another version is present.

    .PARAMETER Version
    Specifies the three-part Platform Tools package version to install. When omitted, the Android CLI selects the current package version and an existing platform-tools directory is kept.

    .EXAMPLE
    Install-WUAndroidPlatformTool

    Installs Platform Tools when adb.exe is missing.

    .EXAMPLE
    Install-WUAndroidPlatformTool -Version '37.0.1'

    Installs Platform Tools version 37.0.1.

    .INPUTS
    None

    .OUTPUTS
    None
    #>
    [CmdletBinding(SupportsShouldProcess = $true)]
    param(
        [Parameter()]
        [Alias('PlatformToolsVersion')]
        [ValidatePattern('^[0-9]+\.[0-9]+\.[0-9]+$')]
        [string]$Version
    )

    $platformToolsPath = Join-Path -Path $env:ANDROID_HOME -ChildPath 'platform-tools'
    $adbPath = Join-Path -Path $platformToolsPath -ChildPath 'adb.exe'
    $hasVersion = $PSBoundParameters.ContainsKey('Version')
    if (-not $hasVersion -and (Test-Path -LiteralPath $adbPath)) {
        return
    }

    $package = if ($hasVersion) { "platform-tools@$Version" } else { 'platform-tools' }
    $arguments = @('--no-metrics', 'sdk', 'install', $package)
    if ($hasVersion) {
        $arguments += '--force'
    }
    if (-not $PSCmdlet.ShouldProcess("Platform Tools package '$package'", 'Install Android SDK component')) {
        return
    }
    Invoke-WUNativeCommand -Command 'android.exe' -ArgumentList $arguments -CaptureOutput -ContinueExitCodes @(-1073740791) -ErrorAction Stop |
        Out-Null
}
