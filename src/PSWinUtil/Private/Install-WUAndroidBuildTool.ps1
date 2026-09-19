function Install-WUAndroidBuildTool {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [ValidatePattern('^[0-9]+\.[0-9]+\.[0-9]+$')]
        [string]$Version
    )

    $buildToolsPath = Join-Path -Path $env:ANDROID_HOME -ChildPath "build-tools\$Version"
    $aapt2Path = Join-Path -Path $buildToolsPath -ChildPath 'aapt2.exe'
    if (Test-Path -LiteralPath $aapt2Path) {
        return
    }

    Invoke-WUAndroidSdkInstall -Package "build-tools/$Version"
}
