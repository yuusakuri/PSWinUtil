function Install-WUAndroidSdk {
    <#
    .SYNOPSIS
    Installs and configures an Android SDK with Android CLI.

    .DESCRIPTION
    Installs Google.AndroidCLI through Windows Package Manager and uses android.exe on PATH to install missing cmdline-tools/latest, platform-tools, SDK Platform, Build Tools, and emulator packages under the configured ANDROID_HOME. Set ANDROID_HOME before running this command. The cmdline-tools/latest/bin directory remains available for sdkmanager, avdmanager, and other established command-line tools. Omitted versions select the latest stable package reported by android sdk list. The command persists ANDROID_HOME and SDK command directories for the current user, refreshes the current process from the persistent environment, and points build-tools\latest to the selected Build Tools version.

    .PARAMETER PlatformVersion
    Specifies the Android SDK Platform API level. The greatest stable available API level is used when omitted.

    .PARAMETER BuildToolsVersion
    Specifies a three-part Android SDK Build Tools version. The greatest stable available version is used when omitted.

    .EXAMPLE
    Install-WUAndroidSdk

    Installs missing SDK components under ANDROID_HOME by using the latest stable Platform and Build Tools versions.

    .EXAMPLE
    Install-WUAndroidSdk -PlatformVersion 36 -BuildToolsVersion '36.0.0'

    Installs missing SDK components for Android API level 36 and Build Tools 36.0.0.

    .INPUTS
    None

    .OUTPUTS
    System.IO.DirectoryInfo

    .NOTES
    Successful configuration removes the deprecated ANDROID_SDK_ROOT variable from the User and Process scopes.

    .LINK
    https://developer.android.com/tools/variables
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

    $fullSdkPath = ConvertTo-WUFullPath -Path $env:ANDROID_HOME
    if (-not $PSCmdlet.ShouldProcess($fullSdkPath, 'Install and configure Android SDK')) {
        return
    }

    Install-WUWingetPackage -Id 'Google.AndroidCLI' | Out-Null
    Update-WUProcessEnvironment
    Assert-WUCommand -Name 'android.exe'
    $androidArguments = @(
        '--no-metrics'
        "--sdk=$fullSdkPath"
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

    $platformToolsPath = Join-Path -Path $fullSdkPath -ChildPath 'platform-tools'
    $platformPath = Join-Path `
        -Path $fullSdkPath `
        -ChildPath "platforms\android-$resolvedPlatformVersion"
    $buildToolsRoot = Join-Path -Path $fullSdkPath -ChildPath 'build-tools'
    $buildToolsPath = Join-Path -Path $buildToolsRoot -ChildPath $resolvedBuildToolsVersion
    $emulatorPath = Join-Path -Path $fullSdkPath -ChildPath 'emulator'
    $cmdlineToolsPath = Join-Path -Path $fullSdkPath -ChildPath 'cmdline-tools\latest\bin'

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
    Set-WUEnvironmentVariable `
        -Name 'ANDROID_HOME' `
        -Value $fullSdkPath `
        -Scope 'User'
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

    Remove-WUEnvironmentVariable -Name 'ANDROID_SDK_ROOT' -Scope Process, User

    Get-Item -LiteralPath $fullSdkPath -ErrorAction Stop
}
