function Install-WUAndroidSdk {
    <#
    .SYNOPSIS
    Installs and configures an Android SDK with Android CLI.

    .DESCRIPTION
    Installs Google.AndroidCLI through Windows Package Manager and uses android.exe to install missing platform-tools, SDK Platform, Build Tools, and emulator packages. Omitted versions select the latest stable package reported by android sdk list. The command sets ANDROID_HOME for the current user and process, adds SDK command directories to both PATH values, and points build-tools\latest to the selected Build Tools version.

    .PARAMETER SdkPath
    Specifies the Android SDK directory. The default value is LOCALAPPDATA\Android\Sdk.

    .PARAMETER PlatformVersion
    Specifies the Android SDK Platform API level. The greatest stable available API level is used when omitted.

    .PARAMETER BuildToolsVersion
    Specifies a three-part Android SDK Build Tools version. The greatest stable available version is used when omitted.

    .EXAMPLE
    Install-WUAndroidSdk

    Installs missing SDK components at the default location by using the latest stable Platform and Build Tools versions.

    .EXAMPLE
    Install-WUAndroidSdk -PlatformVersion 36 -BuildToolsVersion '36.0.0'

    Installs missing SDK components for Android API level 36 and Build Tools 36.0.0.

    .EXAMPLE
    Install-WUAndroidSdk -SdkPath 'D:\Android\Sdk'

    Installs and configures the SDK under D:\Android\Sdk.

    .INPUTS
    None

    .OUTPUTS
    System.IO.DirectoryInfo
    #>
    [CmdletBinding(SupportsShouldProcess = $true)]
    [OutputType([System.IO.DirectoryInfo])]
    param(
        [Parameter()]
        [AllowEmptyString()]
        [string]$SdkPath = $(
            if ([string]::IsNullOrWhiteSpace($env:LOCALAPPDATA)) {
                ''
            } else {
                Join-Path -Path $env:LOCALAPPDATA -ChildPath 'Android\Sdk'
            }
        ),

        [Parameter()]
        [ValidateRange(1, 2147483647)]
        [int]$PlatformVersion,

        [Parameter()]
        [ValidatePattern('^[0-9]+\.[0-9]+\.[0-9]+$')]
        [string]$BuildToolsVersion
    )

    if ([string]::IsNullOrWhiteSpace($SdkPath)) {
        throw 'SdkPath is required. Specify it or set LOCALAPPDATA.'
    }
    $fullSdkPath = ConvertTo-WUFullPath -Path $SdkPath
    Assert-WUPathProperty -LiteralPath $fullSdkPath -Container -AllowNonExisting
    if (-not $PSCmdlet.ShouldProcess($fullSdkPath, 'Install and configure Android SDK')) {
        return
    }

    $null = Install-WUWingetPackage -Id 'Google.AndroidCLI' -Confirm:$false
    Update-WUProcessEnvironment -Confirm:$false
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

    $packages = @()
    if (-not (Test-Path -LiteralPath (Join-Path -Path $platformToolsPath -ChildPath 'adb.exe') -PathType Leaf)) {
        $packages += 'platform-tools'
    }
    if (-not (Test-Path -LiteralPath (Join-Path -Path $platformPath -ChildPath 'android.jar') -PathType Leaf)) {
        $packages += "platforms/android-$resolvedPlatformVersion"
    }
    if (-not (Test-Path -LiteralPath (Join-Path -Path $buildToolsPath -ChildPath 'aapt2.exe') -PathType Leaf)) {
        $packages += "build-tools/$resolvedBuildToolsVersion"
    }
    if (-not (Test-Path -LiteralPath (Join-Path -Path $emulatorPath -ChildPath 'emulator.exe') -PathType Leaf)) {
        $packages += 'emulator'
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

    $requiredFiles = @(
        (Join-Path -Path $platformToolsPath -ChildPath 'adb.exe')
        (Join-Path -Path $platformPath -ChildPath 'android.jar')
        (Join-Path -Path $buildToolsPath -ChildPath 'aapt2.exe')
        (Join-Path -Path $emulatorPath -ChildPath 'emulator.exe')
    )
    foreach ($requiredFile in $requiredFiles) {
        if (-not (Test-Path -LiteralPath $requiredFile -PathType Leaf)) {
            throw "Android CLI did not install an expected file: $requiredFile"
        }
    }

    Set-WUAndroidBuildToolsLatest `
        -BuildToolsPath $buildToolsRoot `
        -Version $resolvedBuildToolsVersion `
        -Confirm:$false
    Set-WUEnvironmentVariable `
        -Name 'ANDROID_HOME' `
        -Value $fullSdkPath `
        -Scope 'User', 'Process' `
        -Confirm:$false
    $userPaths = @(
        '%ANDROID_HOME%\platform-tools'
        '%ANDROID_HOME%\emulator'
        '%ANDROID_HOME%\build-tools\latest'
    )
    Add-WUPathEnvironmentVariable `
        -Path $userPaths `
        -Scope 'User' `
        -Confirm:$false
    $processPaths = @(
        $platformToolsPath
        $emulatorPath
        (Join-Path -Path $buildToolsRoot -ChildPath 'latest')
    )
    Add-WUPathEnvironmentVariable `
        -Path $processPaths `
        -Scope 'Process' `
        -Confirm:$false

    Get-Item -LiteralPath $fullSdkPath -ErrorAction Stop
}
