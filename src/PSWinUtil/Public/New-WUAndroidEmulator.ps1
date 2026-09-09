function New-WUAndroidEmulator {
    <#
    .SYNOPSIS
    Creates an Android virtual device using the latest available Pixel by default.

    .DESCRIPTION
    Uses Android SDK Command-Line Tools to install a system image and create an AVD. By default, selects the greatest numbered standard Pixel profile provided by the installed tools and the greatest stable API available for the requested image tag and ABI. Existing AVDs are preserved unless Force is specified. Java and Android SDK Command-Line Tools must be installed, and the selected package licenses must already be accepted with sdkmanager --licenses. Does not boot the emulator.

    .PARAMETER Name
    Specifies the AVD name. Defaults to DEVICE_API_VERSION after resolving the device and API.

    .PARAMETER Device
    Specifies an avdmanager device ID. Defaults to the newest standard Pixel profile (pixel_N). Update Command-Line Tools to obtain newer profiles.

    .PARAMETER PlatformVersion
    Specifies the Android API level. Defaults to the greatest stable available API for the selected tag and ABI.

    .PARAMETER SystemImageTag
    Specifies the image variant, such as google_apis, google_apis_playstore, or default. Defaults to google_apis.

    .PARAMETER Abi
    Specifies the system image CPU ABI. Defaults to x86_64.

    .PARAMETER SdkPath
    Specifies the SDK root. Defaults to ANDROID_HOME, or LOCALAPPDATA\Android\Sdk when ANDROID_HOME is unset.

    .PARAMETER CommandLineToolsVersion
    Specifies the directory under SDK cmdline-tools. Defaults to latest.

    .PARAMETER Force
    Allows avdmanager to replace an existing AVD with the selected name.

    .EXAMPLE
    New-WUAndroidEmulator

    Creates an AVD for the newest available standard Pixel and stable Android API.

    .EXAMPLE
    New-WUAndroidEmulator -Name 'App_API_35' -Device 'pixel_8' -PlatformVersion 35 -SystemImageTag google_apis_playstore

    Creates a Pixel 8 AVD running Android API 35 with Google Play.

    .EXAMPLE
    New-WUAndroidEmulator -Name 'Preview' -PlatformVersion 35 -WhatIf

    Previews creation without invoking SDK tools or downloading packages.

    .INPUTS
    None

    .OUTPUTS
    System.Management.Automation.PSCustomObject
    #>
    [CmdletBinding(SupportsShouldProcess = $true)]
    [OutputType([pscustomobject])]
    param(
        [Parameter()]
        [ValidatePattern('^[A-Za-z0-9][A-Za-z0-9_.-]*$')]
        [string]$Name,

        [Parameter()]
        [ValidatePattern('^[A-Za-z0-9][A-Za-z0-9_. -]*$')]
        [string]$Device,

        [Parameter()]
        [ValidateRange(1, 2147483647)]
        [int]$PlatformVersion,

        [Parameter()]
        [ValidatePattern('^[a-z0-9_]+$')]
        [string]$SystemImageTag = 'google_apis',

        [Parameter()]
        [ValidateSet('x86_64', 'arm64-v8a', 'x86', 'armeabi-v7a')]
        [string]$Abi = 'x86_64',

        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [string]$SdkPath = $(
            if (-not [string]::IsNullOrWhiteSpace($env:ANDROID_HOME)) {
                $env:ANDROID_HOME
            } else {
                Join-Path -Path $env:LOCALAPPDATA -ChildPath 'Android\Sdk'
            }
        ),

        [Parameter()]
        [ValidatePattern('^(latest|[0-9]+(?:\.[0-9]+)*)$')]
        [string]$CommandLineToolsVersion = 'latest',

        [Parameter()]
        [switch]$Force
    )

    $fullSdkPath = ConvertTo-WUFullPath -Path $SdkPath
    if (-not $PSCmdlet.ShouldProcess($fullSdkPath, "Install system image and create Android AVD '$Name'")) {
        return
    }

    $toolsPath = Join-Path -Path $fullSdkPath -ChildPath "cmdline-tools\$CommandLineToolsVersion\bin"
    $avdManager = Join-Path -Path $toolsPath -ChildPath 'avdmanager.bat'
    $sdkManager = Join-Path -Path $toolsPath -ChildPath 'sdkmanager.bat'
    foreach ($toolPath in @($avdManager, $sdkManager)) {
        Assert-WUPathProperty -LiteralPath $toolPath -Leaf
    }

    $savedAndroidHome = $env:ANDROID_HOME
    $savedSdkRoot = $env:ANDROID_SDK_ROOT
    try {
        $env:ANDROID_HOME = $fullSdkPath
        $env:ANDROID_SDK_ROOT = $fullSdkPath
        $devices = @(Invoke-WUAndroidSdkTool -FilePath $avdManager -ArgumentList 'list', 'device', '-c')
        $devices = @($devices | ForEach-Object { $_.Trim() } | Where-Object { $_ })
        if (-not $PSBoundParameters.ContainsKey('Device')) {
            $latestDevice = $devices | Where-Object { $_ -match '^pixel_[0-9]+$' } |
                Sort-Object -Property { [int]($_ -replace '^pixel_', '') } -Descending |
                Select-Object -First 1
            if ([string]::IsNullOrWhiteSpace($latestDevice)) {
                throw 'No standard Pixel profile was found. Update Android SDK Command-Line Tools or specify Device.'
            }
            $Device = $latestDevice
        } elseif ($Device -cnotin $devices) {
            throw "Android device profile was not found: $Device"
        }

        $listArguments = @("--sdk_root=$fullSdkPath", '--list', '--channel=0')
        $packages = @(Invoke-WUAndroidSdkTool -FilePath $sdkManager -ArgumentList $listArguments)
        $imagePattern = '^\s*system-images;android-([0-9]+);' + [regex]::Escape($SystemImageTag) + ';' + [regex]::Escape($Abi) + '\s+\|'
        $availableVersions = @(
            foreach ($line in $packages) {
                if ($line -match $imagePattern) {
                    [int]$Matches[1]
                }
            }
        )
        if (-not $PSBoundParameters.ContainsKey('PlatformVersion')) {
            if ($availableVersions.Count -eq 0) {
                throw "No stable Android system image is available for $SystemImageTag/$Abi."
            }
            $PlatformVersion = $availableVersions | Sort-Object -Descending -Unique | Select-Object -First 1
        } elseif ($PlatformVersion -notin $availableVersions) {
            throw "No stable Android API $PlatformVersion system image is available for $SystemImageTag/$Abi."
        }
        if (-not $PSBoundParameters.ContainsKey('Name')) {
            $Name = ($Device -replace ' ', '_') + "_API_$PlatformVersion"
        }

        $existingNames = @(Invoke-WUAndroidSdkTool -FilePath $avdManager -ArgumentList 'list', 'avd', '-c')
        if ($Name -in $existingNames -and -not $Force) {
            throw "Android AVD already exists: $Name. Choose another name or specify Force to replace it."
        }

        $package = "system-images;android-$PlatformVersion;${SystemImageTag};$Abi"
        $installArguments = @("--sdk_root=$fullSdkPath", '--install', $package, '--channel=0')
        $null = Invoke-WUAndroidSdkTool -FilePath $sdkManager -ArgumentList $installArguments
        $createArguments = @('create', 'avd', '--name', $Name, '--package', $package, '--device', $Device)
        if ($Force) {
            $createArguments += '--force'
        }
        $null = Invoke-WUAndroidSdkTool -FilePath $avdManager -ArgumentList $createArguments

        [pscustomobject]@{
            Name = $Name
            Device = $Device
            PlatformVersion = $PlatformVersion
            SystemImage = $package
            SdkPath = $fullSdkPath
        }
    } finally {
        $env:ANDROID_HOME = $savedAndroidHome
        $env:ANDROID_SDK_ROOT = $savedSdkRoot
    }
}
