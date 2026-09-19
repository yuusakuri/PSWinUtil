function New-WUAndroidEmulator {
    <#
    .SYNOPSIS
    Creates an Android virtual device using the latest available Pixel by default.

    .DESCRIPTION
    Uses Android CLI to install a system image and avdmanager to create an AVD. By default, selects the greatest numbered standard Pixel profile provided by the installed tools, the greatest stable API available for the requested image tag and ABI, and its latest system image package version. Existing AVDs are preserved unless Force is specified. Android CLI and avdmanager must be available on PATH. Java and Android SDK Command-Line Tools must be installed. Does not boot the emulator or change installed SDK tool versions.

    .PARAMETER Name
    Specifies the AVD name. Defaults to DEVICE_API_VERSION after resolving the device and API.

    .PARAMETER Device
    Specifies an avdmanager device ID. Defaults to the newest standard Pixel profile (pixel_N). Update Command-Line Tools to obtain newer profiles.

    .PARAMETER PlatformVersion
    Specifies the Android API level. Defaults to the greatest stable available API for the selected tag and ABI.

    .PARAMETER SystemImageVersion
    Specifies the three-part system image package version reported by android sdk list --all --all-versions, independently of the API level. Defaults to the latest available version for the selected API, tag, and ABI. An explicit version allows Android CLI to downgrade the shared SDK image package; other AVDs using that package also use the selected version.

    .PARAMETER SystemImageTag
    Specifies the image variant, such as google_apis, google_apis_playstore, or default. Defaults to google_apis.

    .PARAMETER Abi
    Specifies the system image CPU ABI. Defaults to x86_64.

    .PARAMETER Force
    Allows avdmanager to replace an existing AVD with the selected name.

    .EXAMPLE
    New-WUAndroidEmulator

    Creates an AVD for the newest available standard Pixel and stable Android API.

    .EXAMPLE
    New-WUAndroidEmulator -Name 'App_API_35' -Device 'pixel_8' -PlatformVersion 35 -SystemImageTag google_apis_playstore

    Creates a Pixel 8 AVD running Android API 35 with Google Play.

    .EXAMPLE
    New-WUAndroidEmulator -PlatformVersion 29 -SystemImageTag default -SystemImageVersion '8.0.0'

    Creates an AVD using Android API 29 and version 8.0.0 of its default x86_64 system image package, provided that version is available.

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
        [ValidatePattern('^[0-9]+\.[0-9]+\.[0-9]+$')]
        [string]$SystemImageVersion,

        [Parameter()]
        [ValidatePattern('^[a-z0-9_]+$')]
        [string]$SystemImageTag = 'google_apis',

        [Parameter()]
        [ValidateSet('x86_64', 'arm64-v8a', 'x86', 'armeabi-v7a')]
        [string]$Abi = 'x86_64',

        [Parameter()]
        [switch]$Force
    )

    if (-not $PSCmdlet.ShouldProcess("Android AVD '$Name'", 'Install system image and create')) {
        return
    }

    Assert-WUCommand -Name 'android'

    $savedErrorActionPreference = $ErrorActionPreference
    try {
        $ErrorActionPreference = 'Continue'
        $devices = @(Get-WUAndroidDevice -ErrorAction Stop)
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

        $listArguments = @('--no-metrics', 'sdk', 'list', 'system-images/*', '--all', '--all-versions')
        $packageOutput = @(& 'android' @listArguments 2>&1)
        $packageExitCode = $LASTEXITCODE
        $packageLines = @($packageOutput | ForEach-Object { $_.ToString() })
        if ($packageExitCode -ne 0 -and $packageExitCode -ne -1073740791) {
            throw "android failed with exit code $packageExitCode.$([Environment]::NewLine)$($packageLines -join [Environment]::NewLine)"
        }
        $packages = $packageLines
        $imagePattern = '^\s*system-images/android-([0-9]+)/' + [regex]::Escape($SystemImageTag) + '/' + [regex]::Escape($Abi) + '\s+([0-9]+\.[0-9]+\.[0-9]+)\s+'
        $availableImages = @(
            foreach ($line in $packages) {
                if ($line -match $imagePattern) {
                    [pscustomobject]@{
                        PlatformVersion = [int]$Matches[1]
                        Version = $Matches[2]
                    }
                }
            }
        )
        $availableVersions = @($availableImages | ForEach-Object { $_.PlatformVersion })
        if (-not $PSBoundParameters.ContainsKey('PlatformVersion')) {
            if ($availableVersions.Count -eq 0) {
                throw "No stable Android system image is available for $SystemImageTag/$Abi."
            }
            $PlatformVersion = $availableVersions | Sort-Object -Descending -Unique | Select-Object -First 1
        } elseif ($PlatformVersion -notin $availableVersions) {
            throw "No stable Android API $PlatformVersion system image is available for $SystemImageTag/$Abi."
        }
        $imageVersions = @($availableImages | Where-Object { $_.PlatformVersion -eq $PlatformVersion } |
                ForEach-Object { $_.Version })
        if (-not $PSBoundParameters.ContainsKey('SystemImageVersion')) {
            $SystemImageVersion = $imageVersions | Sort-Object -Property { [version]$_ } -Descending |
                Select-Object -First 1
        } elseif ($SystemImageVersion -notin $imageVersions) {
            throw "No stable Android API $PlatformVersion system image version $SystemImageVersion is available for $SystemImageTag/$Abi."
        }
        if (-not $PSBoundParameters.ContainsKey('Name')) {
            $Name = ($Device -replace ' ', '_') + "_API_$PlatformVersion"
        }

        $existingNames = @(Get-WUAndroidEmulator -ErrorAction Stop)
        if ($Name -in $existingNames -and -not $Force) {
            throw "Android AVD already exists: $Name. Choose another name or specify Force to replace it."
        }

        $package = "system-images;android-$PlatformVersion;${SystemImageTag};$Abi"
        $installArguments = @('--no-metrics', 'sdk', 'install', ($package.Replace(';', '/') + "@$SystemImageVersion"))
        if ($PSBoundParameters.ContainsKey('SystemImageVersion')) {
            $installArguments += '--force'
        }
        $installOutput = @(& 'android' @installArguments 2>&1)
        $installExitCode = $LASTEXITCODE
        if ($installExitCode -ne 0 -and $installExitCode -ne -1073740791) {
            $installLines = @($installOutput | ForEach-Object { $_.ToString() })
            throw "android failed with exit code $installExitCode.$([Environment]::NewLine)$($installLines -join [Environment]::NewLine)"
        }
        $createArguments = @('create', 'avd', '--name', $Name, '--package', $package, '--device', $Device)
        if ($Force) {
            $createArguments += '--force'
        }
        $createOutput = @(& 'avdmanager.bat' @createArguments 2>&1)
        $createExitCode = $LASTEXITCODE
        if ($createExitCode -ne 0) {
            $createLines = @($createOutput | ForEach-Object { $_.ToString() })
            throw "avdmanager failed with exit code $createExitCode.$([Environment]::NewLine)$($createLines -join [Environment]::NewLine)"
        }

        [pscustomobject]@{
            Name = $Name
            Device = $Device
            PlatformVersion = $PlatformVersion
            SystemImageVersion = $SystemImageVersion
            SystemImage = $package
        }
    } finally {
        $ErrorActionPreference = $savedErrorActionPreference
    }
}
