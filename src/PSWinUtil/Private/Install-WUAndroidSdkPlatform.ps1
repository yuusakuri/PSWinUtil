function Install-WUAndroidSdkPlatform {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$ApiVersion,

        [Parameter()]
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
    Invoke-WUAndroidSdkInstall -Package $package -Force:$hasPackageVersion
}
