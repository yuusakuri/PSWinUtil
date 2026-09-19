function Install-WUAndroidEmulator {
    [CmdletBinding()]
    param(
        [Parameter()]
        [ValidatePattern('^[0-9]+\.[0-9]+\.[0-9]+$')]
        [string]$Version
    )

    $emulatorPath = Join-Path -Path $env:ANDROID_HOME -ChildPath 'emulator'
    $emulatorExecutablePath = Join-Path -Path $emulatorPath -ChildPath 'emulator.exe'
    $hasVersion = $PSBoundParameters.ContainsKey('Version')
    if (-not $hasVersion -and (Test-Path -LiteralPath $emulatorExecutablePath)) {
        return
    }

    $package = if ($hasVersion) { "emulator@$Version" } else { 'emulator' }
    Invoke-WUAndroidSdkInstall -Package $package -Force:$hasVersion
}
