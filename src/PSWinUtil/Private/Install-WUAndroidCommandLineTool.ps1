function Install-WUAndroidCommandLineTool {
    [CmdletBinding()]
    param(
        [Parameter()]
        [ValidatePattern('^(latest|[0-9]+\.[0-9]+)$')]
        [string]$Version = 'latest'
    )

    $toolsPath = Join-Path -Path $env:ANDROID_HOME -ChildPath "cmdline-tools\$Version\bin"
    $sdkManagerPath = Join-Path -Path $toolsPath -ChildPath 'sdkmanager.bat'
    $avdManagerPath = Join-Path -Path $toolsPath -ChildPath 'avdmanager.bat'
    if ((Test-Path -LiteralPath $sdkManagerPath) -and (Test-Path -LiteralPath $avdManagerPath)) {
        return
    }

    Invoke-WUAndroidSdkInstall -Package "cmdline-tools/$Version"
}
