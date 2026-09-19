function Install-WUAndroidPlatformTool {
    [CmdletBinding()]
    param(
        [Parameter()]
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
    Invoke-WUAndroidSdkInstall -Package $package -Force:$hasVersion
}
