function Install-WUAndroidSdk {
    <#
    .SYNOPSIS
    Installs Android CLI, SDK Platform, Build Tools, Platform Tools, Emulator, and Command-Line Tools.

    .DESCRIPTION
    Installs the SDK under ANDROID_HOME, using %LOCALAPPDATA%\Android\Sdk when unset. The API level and Build Tools version can be selected with parameters. Sets ANDROID_HOME and PATH in the User and current Process scopes.

    .PARAMETER PlatformVersion
    Specifies the Android SDK Platform API level. The greatest stable available API level is used when omitted.

    .PARAMETER BuildToolsVersion
    Specifies a three-part Android SDK Build Tools version. The greatest stable available version is used when omitted.

    .EXAMPLE
    Install-WUAndroidSdk

    Uses ANDROID_HOME or the standard Windows SDK location and installs the latest stable SDK Platform and Build Tools versions.

    .EXAMPLE
    Install-WUAndroidSdk -PlatformVersion 36 -BuildToolsVersion '36.0.0'

    Installs Android API level 36 and Build Tools 36.0.0 at the selected SDK location.

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
        [string]$BuildToolsVersion
    )

    $targetSdkPath = if ([string]::IsNullOrWhiteSpace($env:ANDROID_HOME)) {
        ConvertTo-WUFullPath -Path (Join-Path -Path $env:LOCALAPPDATA -ChildPath 'Android\Sdk')
    } else {
        ConvertTo-WUFullPath -Path $env:ANDROID_HOME
    }
    if (-not $PSCmdlet.ShouldProcess($targetSdkPath, 'Install and configure Android SDK')) {
        return
    }

    Set-WUEnvironmentVariable `
        -Name 'ANDROID_HOME' `
        -Value $targetSdkPath `
        -Scope User, Process
    Remove-WUEnvironmentVariable -Name 'ANDROID_SDK_ROOT' -Scope User, Process

    Install-WUWingetPackage -Id 'Google.AndroidCLI' | Out-Null
    Update-WUProcessEnvironment
    Assert-WUCommand -Name 'android.exe'
    $androidArguments = @(
        '--no-metrics'
        "--sdk=$env:ANDROID_HOME"
    )

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
            $commandArguments = $androidArguments + @(
                'sdk', 'list', 'platforms/android-*', '--all', '--all-versions'
            )
            $availablePlatforms = @(
                & android.exe @commandArguments 2>&1
            )
            $exitCode = $LASTEXITCODE
            $textOutput = @($availablePlatforms | ForEach-Object { $_.ToString() })
            if ($exitCode -ne 0) {
                throw "android.exe failed with exit code $exitCode.$([Environment]::NewLine)$($textOutput -join [Environment]::NewLine)"
            }
            $resolvedPlatformVersion = Get-WUAndroidPlatformVersion `
                -InputObject $availablePlatforms
        }
        if ($null -eq $resolvedBuildToolsVersion) {
            $commandArguments = $androidArguments + @(
                'sdk', 'list', 'build-tools/*', '--all', '--all-versions'
            )
            $availableBuildTools = @(
                & android.exe @commandArguments 2>&1
            )
            $exitCode = $LASTEXITCODE
            $textOutput = @($availableBuildTools | ForEach-Object { $_.ToString() })
            if ($exitCode -ne 0) {
                throw "android.exe failed with exit code $exitCode.$([Environment]::NewLine)$($textOutput -join [Environment]::NewLine)"
            }
            $resolvedBuildToolsVersion = Get-WUAndroidBuildToolsVersion `
                -InputObject $availableBuildTools
        }
    }

    $platformToolsPath = Join-Path -Path $env:ANDROID_HOME -ChildPath 'platform-tools'
    $platformPath = Join-Path `
        -Path $env:ANDROID_HOME `
        -ChildPath "platforms\android-$resolvedPlatformVersion"
    $buildToolsRoot = Join-Path -Path $env:ANDROID_HOME -ChildPath 'build-tools'
    $buildToolsPath = Join-Path -Path $buildToolsRoot -ChildPath $resolvedBuildToolsVersion
    $emulatorPath = Join-Path -Path $env:ANDROID_HOME -ChildPath 'emulator'
    $cmdlineToolsPath = Join-Path -Path $env:ANDROID_HOME -ChildPath 'cmdline-tools\latest\bin'

    $packages = @()
    if (-not (Test-Path -LiteralPath (Join-Path -Path $platformToolsPath -ChildPath 'adb.exe'))) {
        $packages += 'platform-tools'
    }
    if (-not (Test-Path -LiteralPath (Join-Path -Path $platformPath -ChildPath 'android.jar'))) {
        $packages += "platforms/android-$resolvedPlatformVersion"
    }
    if (-not (Test-Path -LiteralPath (Join-Path -Path $buildToolsPath -ChildPath 'aapt2.exe'))) {
        $packages += "build-tools/$resolvedBuildToolsVersion"
    }
    if (-not (Test-Path -LiteralPath (Join-Path -Path $emulatorPath -ChildPath 'emulator.exe'))) {
        $packages += 'emulator'
    }
    if (
        -not (Test-Path -LiteralPath (Join-Path -Path $cmdlineToolsPath -ChildPath 'sdkmanager.bat')) -or
        -not (Test-Path -LiteralPath (Join-Path -Path $cmdlineToolsPath -ChildPath 'avdmanager.bat'))
    ) {
        $packages += 'cmdline-tools/latest'
    }

    if ($packages.Count -gt 0) {
        $installArguments = @('sdk', 'install') + $packages
        $commandArguments = $androidArguments + $installArguments
        $installOutput = @(
            & android.exe @commandArguments 2>&1
        )
        $exitCode = $LASTEXITCODE
        $textOutput = @($installOutput | ForEach-Object { $_.ToString() })
        if ($exitCode -ne 0) {
            throw "android.exe failed with exit code $exitCode.$([Environment]::NewLine)$($textOutput -join [Environment]::NewLine)"
        }
    }

    Set-WUAndroidBuildToolsLatest `
        -BuildToolsPath $buildToolsRoot `
        -Version $resolvedBuildToolsVersion
    $userPaths = @(
        '%ANDROID_HOME%\platform-tools'
        '%ANDROID_HOME%\emulator'
        '%ANDROID_HOME%\build-tools\latest'
        '%ANDROID_HOME%\cmdline-tools\latest\bin'
    )
    Add-WUPathEnvironmentVariable `
        -Path $userPaths `
        -Scope 'User'
    Update-WUProcessEnvironment

    foreach ($commandName in @('adb.exe', 'aapt2.exe', 'emulator.exe', 'sdkmanager.bat', 'avdmanager.bat')) {
        Assert-WUCommand -Name $commandName
    }

    Get-Item -LiteralPath $env:ANDROID_HOME -ErrorAction Stop
}
