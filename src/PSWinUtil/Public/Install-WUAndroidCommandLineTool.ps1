function Install-WUAndroidCommandLineTool {
    <#
    .SYNOPSIS
    Installs the Android SDK Command-Line Tools package.

    .DESCRIPTION
    Installs the requested Command-Line Tools package selected by the Android CLI in $env:ANDROID_HOME when sdkmanager.bat or avdmanager.bat is missing.

    .PARAMETER Version
    Specifies the Command-Line Tools package version, such as latest or 22.0.

    .EXAMPLE
    Install-WUAndroidCommandLineTool

    Installs the latest Command-Line Tools package when either command-line tool is missing.

    .EXAMPLE
    Install-WUAndroidCommandLineTool -Version '22.0'

    Installs Command-Line Tools version 22.0 when either command-line tool is missing.

    .INPUTS
    None

    .OUTPUTS
    None
    #>
    [CmdletBinding(SupportsShouldProcess = $true)]
    param(
        [Parameter()]
        [Alias('CommandLineToolsVersion')]
        [ValidatePattern('^(latest|[0-9]+\.[0-9]+)$')]
        [string]$Version = 'latest'
    )

    $toolsPath = Join-Path -Path $env:ANDROID_HOME -ChildPath "cmdline-tools\$Version\bin"
    $sdkManagerPath = Join-Path -Path $toolsPath -ChildPath 'sdkmanager.bat'
    $avdManagerPath = Join-Path -Path $toolsPath -ChildPath 'avdmanager.bat'
    if ((Test-Path -LiteralPath $sdkManagerPath) -and (Test-Path -LiteralPath $avdManagerPath)) {
        return
    }

    $package = "cmdline-tools/$Version"
    $arguments = @('--no-metrics', 'sdk', 'install', $package)
    if (-not $PSCmdlet.ShouldProcess("Command-Line Tools package '$Version'", 'Install Android SDK component')) {
        return
    }
    Invoke-WUNativeCommand `
        -Command 'android.exe' `
        -ArgumentList $arguments `
        -CaptureOutput `
        -ContinueExitCodes @(-1073740791) `
        -ErrorAction Stop |
        Out-Null
}
