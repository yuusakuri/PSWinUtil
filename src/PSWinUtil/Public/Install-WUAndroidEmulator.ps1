function Install-WUAndroidEmulator {
    <#
    .SYNOPSIS
    Installs the Android Emulator package when it is missing or a version is requested.

    .DESCRIPTION
    Installs the Android Emulator package selected by the Android CLI in $env:ANDROID_HOME. An explicit version is installed even when another version is present.

    .PARAMETER Version
    Specifies the three-part Android Emulator package version to install. When omitted, the Android CLI selects the current package version and an existing emulator is kept.

    .EXAMPLE
    Install-WUAndroidEmulator

    Installs the Android Emulator package when emulator.exe is missing.

    .EXAMPLE
    Install-WUAndroidEmulator -Version '37.1.11'

    Installs Android Emulator version 37.1.11.

    .INPUTS
    None

    .OUTPUTS
    None
    #>
    [CmdletBinding(SupportsShouldProcess = $true)]
    param(
        [Parameter()]
        [Alias('EmulatorVersion')]
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
    $arguments = @('--no-metrics', 'sdk', 'install', $package)
    if ($hasVersion) {
        $arguments += '--force'
    }
    if (-not $PSCmdlet.ShouldProcess("Android Emulator package '$package'", 'Install Android SDK component')) {
        return
    }
    Invoke-WUNativeCommand -Command 'android.exe' -ArgumentList $arguments -CaptureOutput -ContinueExitCodes @(-1073740791) -ErrorAction Stop |
        Out-Null
}
