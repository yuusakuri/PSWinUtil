function Install-WUAndroidSdk {
    <#
    .SYNOPSIS
    Installs and configures an Android SDK with Android CLI.

    .DESCRIPTION
    Installs Google.AndroidCLI through Windows Package Manager and uses android.exe on PATH to install Command-Line Tools, Platform Tools, SDK Platform, Build Tools, and emulator packages under the configured ANDROID_HOME. Set ANDROID_HOME before running this command. The selected cmdline-tools/VERSION/bin directory remains available for sdkmanager, avdmanager, and other established command-line tools. Missing packages use the latest stable version when a version is omitted; existing packages are preserved. Explicit package versions are applied even when files already exist and allow downgrading the shared SDK packages. The command persists ANDROID_HOME and SDK command directories for the current user, refreshes the current process from the persistent environment, and points build-tools\latest to the selected Build Tools version.

    .PARAMETER PlatformVersion
    Specifies the Android SDK Platform API level. The greatest stable available API level is used when omitted.

    .PARAMETER BuildToolsVersion
    Specifies a three-part Android SDK Build Tools version. The greatest stable available version is used when omitted.

    .PARAMETER CommandLineToolsVersion
    Specifies the stable Command-Line Tools package identifier, such as 22.0, from cmdline-tools/VERSION. Defaults to latest. The selected version's bin directory is added to the user PATH.

    .PARAMETER PlatformToolsVersion
    Specifies the three-part platform-tools package version reported by android sdk list. When omitted, installs the latest stable version only if Platform Tools are missing.

    .PARAMETER EmulatorVersion
    Specifies the three-part emulator package version reported by android sdk list. When omitted, installs the latest stable version only if the emulator is missing.

    .PARAMETER PlatformPackageVersion
    Specifies the three-part SDK Platform package version reported by android sdk list, independently of the PlatformVersion API level. When omitted, installs the latest stable package version only if that API's SDK Platform is missing.

    .EXAMPLE
    Install-WUAndroidSdk

    Installs missing SDK components under ANDROID_HOME by using the latest stable Platform and Build Tools versions.

    .EXAMPLE
    Install-WUAndroidSdk -PlatformVersion 36 -BuildToolsVersion '36.0.0'

    Installs missing SDK components for Android API level 36 and Build Tools 36.0.0.

    .EXAMPLE
    Install-WUAndroidSdk -PlatformVersion 36 -BuildToolsVersion '36.0.0' -CommandLineToolsVersion '22.0' -PlatformPackageVersion '2.0.0' -PlatformToolsVersion '37.0.1' -EmulatorVersion '37.1.11'

    Installs the specified SDK component versions, provided they are available, and registers cmdline-tools\22.0\bin on PATH.

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
            $savedErrorActionPreference = $ErrorActionPreference
            try {
                $ErrorActionPreference = 'Continue'
                $availablePlatforms = @(& android.exe @commandArguments 2>&1)
                $exitCode = $LASTEXITCODE
            } finally {
                $ErrorActionPreference = $savedErrorActionPreference
            }
            $textOutput = @($availablePlatforms | ForEach-Object { $_.ToString() })
            if ($exitCode -ne 0 -and $exitCode -ne -1073740791) {
                throw "android.exe failed with exit code $exitCode.$([Environment]::NewLine)$($textOutput -join [Environment]::NewLine)"
            }
            $resolvedPlatformVersion = Get-WUAndroidPlatformVersion `
                -InputObject $availablePlatforms
        }
        if ($null -eq $resolvedBuildToolsVersion) {
            $commandArguments = $androidArguments + @(
                'sdk', 'list', 'build-tools/*', '--all', '--all-versions'
            )
            $savedErrorActionPreference = $ErrorActionPreference
            try {
                $ErrorActionPreference = 'Continue'
                $availableBuildTools = @(& android.exe @commandArguments 2>&1)
                $exitCode = $LASTEXITCODE
            } finally {
                $ErrorActionPreference = $savedErrorActionPreference
            }
            $textOutput = @($availableBuildTools | ForEach-Object { $_.ToString() })
            if ($exitCode -ne 0 -and $exitCode -ne -1073740791) {
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
    $cmdlineToolsPath = Join-Path -Path $fullSdkPath -ChildPath "cmdline-tools\$CommandLineToolsVersion\bin"

    $packages = @()
    if ($PSBoundParameters.ContainsKey('PlatformToolsVersion') -or -not (Test-Path -LiteralPath (Join-Path -Path $platformToolsPath -ChildPath 'adb.exe'))) {
        $packages += if ($PSBoundParameters.ContainsKey('PlatformToolsVersion')) {
            "platform-tools@$PlatformToolsVersion"
        } else {
            'platform-tools'
        }
    }
    if ($PSBoundParameters.ContainsKey('PlatformPackageVersion') -or -not (Test-Path -LiteralPath (Join-Path -Path $platformPath -ChildPath 'android.jar'))) {
        $packages += if ($PSBoundParameters.ContainsKey('PlatformPackageVersion')) {
            "platforms/android-$resolvedPlatformVersion@$PlatformPackageVersion"
        } else {
            "platforms/android-$resolvedPlatformVersion"
        }
    }
    if (-not (Test-Path -LiteralPath (Join-Path -Path $buildToolsPath -ChildPath 'aapt2.exe'))) {
        $packages += "build-tools/$resolvedBuildToolsVersion"
    }
    if ($PSBoundParameters.ContainsKey('EmulatorVersion') -or -not (Test-Path -LiteralPath (Join-Path -Path $emulatorPath -ChildPath 'emulator.exe'))) {
        $packages += if ($PSBoundParameters.ContainsKey('EmulatorVersion')) {
            "emulator@$EmulatorVersion"
        } else {
            'emulator'
        }
    }
    if (
        -not (Test-Path -LiteralPath (Join-Path -Path $cmdlineToolsPath -ChildPath 'sdkmanager.bat')) -or
        -not (Test-Path -LiteralPath (Join-Path -Path $cmdlineToolsPath -ChildPath 'avdmanager.bat'))
    ) {
        $packages += "cmdline-tools/$CommandLineToolsVersion"
    }

    if ($packages.Count -gt 0) {
        $installArguments = @('sdk', 'install') + $packages
        if ($packages -match '@') {
            $installArguments += '--force'
        }
        $commandArguments = $androidArguments + $installArguments
        $savedErrorActionPreference = $ErrorActionPreference
        try {
            $ErrorActionPreference = 'Continue'
            $installOutput = @(& android.exe @commandArguments 2>&1)
            $exitCode = $LASTEXITCODE
        } finally {
            $ErrorActionPreference = $savedErrorActionPreference
        }
        $textOutput = @($installOutput | ForEach-Object { $_.ToString() })
        # Android CLI 1.0.16261425 can exit with 0xC0000409 after SDK output on Windows.
        if ($exitCode -ne 0 -and $exitCode -ne -1073740791) {
            throw "android.exe failed with exit code $exitCode.$([Environment]::NewLine)$($textOutput -join [Environment]::NewLine)"
        }
    }

    $versionedPackages = @{
        PlatformToolsVersion = $platformToolsPath
        EmulatorVersion = $emulatorPath
        PlatformPackageVersion = $platformPath
    }
    foreach ($parameterName in $versionedPackages.Keys) {
        if (-not $PSBoundParameters.ContainsKey($parameterName)) {
            continue
        }
        $propertiesPath = Join-Path $versionedPackages[$parameterName] 'source.properties'
        $properties = Get-Content -LiteralPath $propertiesPath -Raw -ErrorAction Stop
        $revision = [regex]::Match($properties, '(?m)^Pkg.Revision\s*=\s*([0-9]+)(?:\.([0-9]+))?(?:\.([0-9]+))?\s*$')
        if (-not $revision.Success) {
            throw "Android package revision was not found: $propertiesPath"
        }
        $installedVersion = [version]::new([int]$revision.Groups[1].Value, [int]$revision.Groups[2].Value, [int]$revision.Groups[3].Value)
        if ($installedVersion -ne [version]$PSBoundParameters[$parameterName]) {
            throw "Android CLI did not install $parameterName $($PSBoundParameters[$parameterName]); installed version is $installedVersion."
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
        "%ANDROID_HOME%\cmdline-tools\$CommandLineToolsVersion\bin"
    )
    Add-WUPathEnvironmentVariable `
        -Path $userPaths `
        -Scope 'User' `
        -Prepend
    Update-WUProcessEnvironment

    foreach ($commandName in @('adb.exe', 'aapt2.exe', 'emulator.exe', 'sdkmanager.bat', 'avdmanager.bat')) {
        Assert-WUCommand -Name $commandName
    }

    Remove-WUEnvironmentVariable -Name 'ANDROID_SDK_ROOT' -Scope Process, User

    Get-Item -LiteralPath $fullSdkPath -ErrorAction Stop
}
