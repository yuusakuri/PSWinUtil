function Install-WUAndroidSdkPlatform {
    <#
    .SYNOPSIS
    Installs an Android SDK Platform package for an API level.

    .DESCRIPTION
    Installs the Android SDK Platform package selected by the Android CLI in $env:ANDROID_HOME. An explicit package version is installed even when another version is present.

    .PARAMETER ApiVersion
    Specifies the Android API level of the SDK Platform package.

    .PARAMETER PackageVersion
    Specifies the three-part SDK Platform package version to install. When omitted, an existing android.jar is kept.

    .EXAMPLE
    Install-WUAndroidSdkPlatform -ApiVersion 36

    Installs the SDK Platform package for API level 36 when it is missing.

    .EXAMPLE
    Install-WUAndroidSdkPlatform -ApiVersion 36 -PackageVersion '2.0.0'

    Installs SDK Platform package version 2.0.0 for API level 36.

    .INPUTS
    None

    .OUTPUTS
    None
    #>
    [CmdletBinding(SupportsShouldProcess = $true)]
    param(
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$ApiVersion,

        [Parameter()]
        [Alias('PlatformPackageVersion')]
        [ValidatePattern('^[0-9]+\.[0-9]+\.[0-9]+$')]
        [string]$PackageVersion
    )

    $platformPath = Join-Path -Path $env:ANDROID_HOME -ChildPath "platforms\android-$ApiVersion"
    $androidJarPath = Join-Path -Path $platformPath -ChildPath 'android.jar'
    $hasPackageVersion = $PSBoundParameters.ContainsKey('PackageVersion')
    if (-not $hasPackageVersion -and (Test-Path -LiteralPath $androidJarPath)) {
        return
    }

    $package = "platforms/android-$ApiVersion"
    if ($hasPackageVersion) {
        $package = "$package@$PackageVersion"
    }
    $arguments = @('--no-metrics', 'sdk', 'install', $package)
    if ($hasPackageVersion) {
        $arguments += '--force'
    }
    if (-not $PSCmdlet.ShouldProcess("Android SDK Platform package '$package'", 'Install Android SDK component')) {
        return
    }
    Invoke-WUNativeCommand -Command 'android.exe' -ArgumentList $arguments -CaptureOutput -ContinueExitCodes @(-1073740791) -ErrorAction Stop |
        Out-Null
}
