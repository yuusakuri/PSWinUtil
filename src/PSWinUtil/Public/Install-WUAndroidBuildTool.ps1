function Install-WUAndroidBuildTool {
    <#
    .SYNOPSIS
    Installs an Android SDK Build Tools package.

    .DESCRIPTION
    Installs the requested Build Tools package selected by the Android CLI in $env:ANDROID_HOME when its aapt2.exe is missing.

    .PARAMETER Version
    Specifies the three-part Android SDK Build Tools package version to install.

    .EXAMPLE
    Install-WUAndroidBuildTool -Version '36.0.0'

    Installs Build Tools version 36.0.0 when it is missing.

    .INPUTS
    None

    .OUTPUTS
    None
    #>
    [CmdletBinding(SupportsShouldProcess = $true)]
    param(
        [Parameter(Mandatory = $true)]
        [Alias('BuildToolsVersion')]
        [ValidatePattern('^[0-9]+\.[0-9]+\.[0-9]+$')]
        [string]$Version
    )

    $buildToolsPath = Join-Path -Path $env:ANDROID_HOME -ChildPath "build-tools\$Version"
    $aapt2Path = Join-Path -Path $buildToolsPath -ChildPath 'aapt2.exe'
    if (Test-Path -LiteralPath $aapt2Path) {
        return
    }

    $package = "build-tools/$Version"
    $arguments = @('--no-metrics', 'sdk', 'install', $package)
    if (-not $PSCmdlet.ShouldProcess("Build Tools package '$Version'", 'Install Android SDK component')) {
        return
    }
    Invoke-WUNativeCommand -Command 'android.exe' -ArgumentList $arguments -CaptureOutput -ContinueExitCodes @(-1073740791) -ErrorAction Stop |
        Out-Null
}
