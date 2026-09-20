function Install-WUAndroidSdk {
    <#
    .SYNOPSIS
    Installs Android CLI, SDK Platform, Build Tools, Platform Tools, Emulator, and Command-Line Tools.

    .DESCRIPTION
    Installs the SDK under $env:ANDROID_HOME, using $env:LOCALAPPDATA\Android\Sdk when unset. The API level and SDK component versions can be selected with parameters. Sets $env:ANDROID_HOME and $env:PATH in the User and current Process scopes.

    .PARAMETER PlatformVersion
    Specifies the Android SDK Platform API level. The greatest stable available API level is used when omitted.

    .PARAMETER BuildToolsVersion
    Specifies a three-part Android SDK Build Tools version. The greatest stable available version is used when omitted.

    .PARAMETER CommandLineToolsVersion
    Specifies the stable Command-Line Tools package identifier, such as 22.0, from cmdline-tools/VERSION. Defaults to latest.

    .PARAMETER PlatformToolsVersion
    Specifies the three-part platform-tools package version reported by android sdk list. When omitted, installs the latest stable version only if Platform Tools are missing.

    .PARAMETER EmulatorVersion
    Specifies the three-part emulator package version reported by android sdk list. When omitted, installs the latest stable version only if the emulator is missing.

    .PARAMETER PlatformPackageVersion
    Specifies the three-part SDK Platform package version reported by android sdk list, independently of the PlatformVersion API level. When omitted, installs the latest stable package version only if that API's SDK Platform is missing.

    .EXAMPLE
    Install-WUAndroidSdk

    Uses $env:ANDROID_HOME or the standard Windows SDK location and installs the latest stable SDK Platform and Build Tools versions.

    .EXAMPLE
    Install-WUAndroidSdk -PlatformVersion 36 -BuildToolsVersion '36.0.0'

    Installs Android API level 36 and Build Tools 36.0.0 at the selected SDK location.

    .EXAMPLE
    Install-WUAndroidSdk -PlatformVersion 36 -BuildToolsVersion '36.0.0' -CommandLineToolsVersion '22.0' -PlatformPackageVersion '2.0.0' -PlatformToolsVersion '37.0.1' -EmulatorVersion '37.1.11'

    Installs the specified versions of the requested SDK components when they are available.

    .INPUTS
    None

    .OUTPUTS
    System.IO.DirectoryInfo

    .LINK
    https://developer.android.com/tools/variables

    .LINK
    https://developer.android.com/studio/emulator_archive
    #>
    [CmdletBinding(SupportsShouldProcess = $true)]
    [OutputType([System.IO.DirectoryInfo])]
    param(
        [Parameter()]
        [ValidateRange(1, 2147483647)]
        [int]$PlatformVersion,

        [Parameter()]
        [ValidatePattern('^[0-9]+\.[0-9]+\.[0-9]+$')]
        [string]$BuildToolsVersion,

        [Parameter()]
        [ValidatePattern('^(latest|[0-9]+\.[0-9]+)$')]
        [string]$CommandLineToolsVersion = 'latest',

        [Parameter()]
        [ValidatePattern('^[0-9]+\.[0-9]+\.[0-9]+$')]
        [string]$PlatformToolsVersion,

        [Parameter()]
        [ValidatePattern('^[0-9]+\.[0-9]+\.[0-9]+$')]
        [string]$EmulatorVersion,

        [Parameter()]
        [ValidatePattern('^[0-9]+\.[0-9]+\.[0-9]+$')]
        [string]$PlatformPackageVersion
    )

    if (-not $PSCmdlet.ShouldProcess('Android SDK', 'Install and configure Android SDK')) {
        return
    }

    if ([string]::IsNullOrWhiteSpace($env:ANDROID_HOME)) {
        $env:ANDROID_HOME = Join-Path -Path $env:LOCALAPPDATA -ChildPath 'Android\Sdk'
    }
    Set-WUEnvironmentVariable `
        -Name 'ANDROID_HOME' `
        -Value $env:ANDROID_HOME `
        -Scope User, Process
    Remove-WUEnvironmentVariable -Name 'ANDROID_SDK_ROOT' -Scope User, Process

    Install-WUWingetPackage -Id 'Google.AndroidCLI'
    Update-WUProcessEnvironment
    Assert-WUCommand -Name 'android.exe'
    $resolvedPlatformVersion = if ($PSBoundParameters.ContainsKey('PlatformVersion')) {
        [string]$PlatformVersion
    } else {
        $null
    }
    $resolvedBuildToolsVersion = if ($PSBoundParameters.ContainsKey('BuildToolsVersion')) {
        $BuildToolsVersion
    } else {
        $null
    }
    if ($null -eq $resolvedPlatformVersion -or $null -eq $resolvedBuildToolsVersion) {
        if ($null -eq $resolvedPlatformVersion) {
            $resolvedPlatformVersion = Get-WUAndroidSdkPackageVersion -Component Platform -Latest
        }
        if ($null -eq $resolvedBuildToolsVersion) {
            $resolvedBuildToolsVersion = Get-WUAndroidSdkPackageVersion -Component BuildTools -Latest
        }
    }

    $buildToolsRoot = Join-Path -Path $env:ANDROID_HOME -ChildPath 'build-tools'

    $platformToolsParameters = Select-WUBoundParameter `
        -BoundParameters $PSBoundParameters `
        -Name 'PlatformToolsVersion'
    Install-WUAndroidPlatformTool @platformToolsParameters

    $platformParameters = @{ ApiVersion = $resolvedPlatformVersion }
    $platformParameters += Select-WUBoundParameter `
        -BoundParameters $PSBoundParameters `
        -Name 'PlatformPackageVersion'
    Install-WUAndroidSdkPlatform @platformParameters

    Install-WUAndroidBuildTool -Version $resolvedBuildToolsVersion

    $emulatorParameters = Select-WUBoundParameter `
        -BoundParameters $PSBoundParameters `
        -Name 'EmulatorVersion'
    Install-WUAndroidEmulator @emulatorParameters

    Install-WUAndroidCommandLineTool -Version $CommandLineToolsVersion

    Set-WUAndroidBuildToolsLatest `
        -BuildToolsPath $buildToolsRoot `
        -Version $resolvedBuildToolsVersion
    $userPaths = @(
        '%ANDROID_HOME%\platform-tools'
        '%ANDROID_HOME%\emulator'
        '%ANDROID_HOME%\build-tools\latest'
        "%ANDROID_HOME%\cmdline-tools\$CommandLineToolsVersion\bin"
    )
    Add-WUPathEnvironmentVariable `
        -Path $userPaths `
        -Scope 'User' `
        -Prepend
    Update-WUProcessEnvironment

    Assert-WUCommand -Name @('adb.exe', 'aapt2.exe', 'emulator.exe', 'sdkmanager.bat', 'avdmanager.bat')

    return [System.IO.DirectoryInfo]::new($env:ANDROID_HOME)
}
