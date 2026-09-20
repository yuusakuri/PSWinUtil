BeforeAll {
    . (Join-Path -Path $PSScriptRoot -ChildPath '../UnitTestBootstrap.ps1')
}

Describe 'Android AVD selection and errors' -Tag Android {
    BeforeEach {
        $script:OriginalAndroidHome = $env:ANDROID_HOME
        $script:OriginalSdkRoot = $env:ANDROID_SDK_ROOT
        $script:OriginalPath = $env:Path
        $script:OriginalAvdHome = $env:ANDROID_AVD_HOME
        $script:AvdHome = Join-Path $TestDrive ([guid]::NewGuid().ToString('N'))
        New-Item -Path $script:AvdHome -ItemType Directory | Out-Null
        $env:ANDROID_AVD_HOME = $script:AvdHome
        $script:ToolDirectory = Join-Path -Path $TestDrive -ChildPath 'android-tools'
        $script:InstallArgumentsPath = Join-Path -Path $TestDrive -ChildPath ('install-arguments-' + [guid]::NewGuid().ToString('N') + '.txt')
        $script:ToolRoot = Join-Path -Path $TestDrive -ChildPath 'sdk'
        $script:AvdManagerDirectory = Join-Path -Path $script:ToolRoot -ChildPath 'cmdline-tools/latest/bin'
        New-Item -Path $script:AvdManagerDirectory -ItemType Directory -Force | Out-Null
        New-Item -Path $script:ToolDirectory -ItemType Directory -Force | Out-Null
        $script:DeviceCatalog = @('pixel_9', 'pixel_10', 'pixel_10_pro', 'pixel_tablet', 'pixel_8')
        $script:PackageCatalog = @(
            'system-images/android-9/google_apis/x86_64 1.0.0 older'
            'system-images/android-35/google_apis/x86_64 1.0.0 stable'
            'system-images/android-36/google_apis/x86_64 1.0.0 stable'
            'system-images/android-36/google_apis/x86_64 9.0.0 stable'
            'system-images/android-36/google_apis/x86_64 10.0.0 stable'
            'system-images/android-Z/google_apis/x86_64 1.0.0 preview'
            'system-images/android-37/google_apis/arm64-v8a 1.0.0 other ABI'
            'system-images/android-35/google_apis_playstore/arm64-v8a 1.0.0 Play'
        )
        $script:InstallExitCode = 0
        function Write-TestAndroidTool {
            $deviceLines = $script:DeviceCatalog -join "`r`necho("
            $packageLines = $script:PackageCatalog -join "`r`necho "
            $avdScript = @'
@echo off
if "%~1"=="list" if "%~2"=="device" (
    echo(DEVICE_LINES
    exit /b 0
)
if "%~1"=="create" if "%~2"=="avd" (
    for /f "tokens=4,6,8,9 delims= " %%A in ("%*") do (
        if exist "AVD_HOME\%%A.avd\config.ini" if not "%%D"=="--force" exit /b 19
        mkdir "AVD_HOME\%%A.avd" >nul 2>&1
        >"AVD_HOME\%%A.avd\config.ini" echo hw.device.name=%%C
        >>"AVD_HOME\%%A.avd\config.ini" echo image.sysdir.1=%%B
    )
    exit /b 0
)
exit /b 23
'@
            $avdScript = $avdScript.Replace('DEVICE_LINES', $deviceLines).Replace('AVD_HOME', $script:AvdHome)
            [IO.File]::WriteAllText((Join-Path $script:AvdManagerDirectory 'avdmanager.bat'), $avdScript)
            $androidScript = "@echo off`r`nif `"%3`"==`"install`" (`r`necho %*>`"$($script:InstallArgumentsPath)`"`r`nexit /b $($script:InstallExitCode)`r`n)`r`necho $packageLines`r`nexit /b 0`r`n"
            [IO.File]::WriteAllText((Join-Path $script:ToolDirectory 'android.cmd'), $androidScript)
        }
        Mock -CommandName Get-WUAndroidEmulator -ModuleName PSWinUtil -MockWith {
            Get-ChildItem -LiteralPath $script:AvdHome -Directory | ForEach-Object { $_.Name -replace '\.avd$', '' }
        }
        Write-TestAndroidTool
        $env:Path = "$($script:AvdManagerDirectory);$($script:ToolDirectory);$($script:OriginalPath)"
    }

    AfterEach {
        $env:ANDROID_HOME = $script:OriginalAndroidHome
        $env:ANDROID_SDK_ROOT = $script:OriginalSdkRoot
        $env:Path = $script:OriginalPath
        $env:ANDROID_AVD_HOME = $script:OriginalAvdHome
    }

    It 'selects the newest standard Pixel and matching stable API numerically' {
        $result = New-WUAndroidEmulator
        $result.Name | Should -Be 'pixel_10_API_36'
        $result.Device | Should -Be 'pixel_10'
        $result.PlatformVersion | Should -Be 36
        $result.SystemImageVersion | Should -Be '10.0.0'
        $result.SystemImage | Should -Be 'system-images;android-36;google_apis;x86_64'
        $configuration = [IO.File]::ReadAllText((Join-Path $script:AvdHome 'pixel_10_API_36.avd/config.ini'))
        $configuration | Should -Match '(?m)^hw.device.name=pixel_10\r?$'
        $configuration | Should -Match '(?m)^image.sysdir.1=system-images;android-36;google_apis;x86_64\r?$'
        $arguments = [IO.File]::ReadAllText($script:InstallArgumentsPath)
        $arguments | Should -Match 'system-images/android-36/google_apis/x86_64@10\.0\.0'
        $arguments | Should -Not -Match '--force'
    }

    It 'pins the image package version independently of the API and allows a downgrade' {
        $result = New-WUAndroidEmulator -PlatformVersion 36 -SystemImageVersion '9.0.0'

        $result.PlatformVersion | Should -Be 36
        $result.SystemImageVersion | Should -Be '9.0.0'
        $arguments = [IO.File]::ReadAllText($script:InstallArgumentsPath)
        $arguments | Should -Match 'system-images/android-36/google_apis/x86_64@9\.0\.0'
        $arguments | Should -Match '--force'
    }

    It 'continues after the observed Windows CLI exit code' {
        $script:InstallExitCode = -1073740791
        Write-TestAndroidTool

        $result = New-WUAndroidEmulator

        $result.Name | Should -Be 'pixel_10_API_36'
    }

    It 'rejects other SDK installation exit codes' -TestCases @(
        @{ ExitCode = 1 }
        @{ ExitCode = 23 }
    ) {
        param($ExitCode)

        $script:InstallExitCode = $ExitCode
        Write-TestAndroidTool

        { New-WUAndroidEmulator } | Should -Throw "*`"exit_code`":$ExitCode*"
    }

    It 'rejects a package version that exists only for a different API before installation' {
        { New-WUAndroidEmulator -PlatformVersion 35 -SystemImageVersion '9.0.0' } |
            Should -Throw '*API 35*version 9.0.0*'

        Test-Path -LiteralPath $script:InstallArgumentsPath | Should -BeFalse
    }

    It 'lists creation profile IDs separately from existing AVD names' {
        New-WUAndroidEmulator -Name custom | Out-Null
        $script:DeviceCatalog = @('  pixel_8  ', ' ', 'pixel_10')
        Write-TestAndroidTool

        $devices = @(Get-WUAndroidDevice)

        $devices | Should -HaveCount 2
        $devices[0] | Should -Be 'pixel_8'
        $devices[1] | Should -Be 'pixel_10'
        $devices | Should -Not -Contain 'custom'
    }

    It 'returns no profile IDs for an empty catalog' {
        $script:DeviceCatalog = @()
        Write-TestAndroidTool

        @(Get-WUAndroidDevice) | Should -HaveCount 0
    }

    It 'requires avdmanager on PATH to list creation profiles' {
        $env:Path = $script:ToolDirectory

        { Get-WUAndroidDevice } | Should -Throw '*Command*not available*'
    }

    It 'honors explicit device, API, tag, ABI and name' {
        $result = New-WUAndroidEmulator -Name custom -Device pixel_8 -PlatformVersion 35 -SystemImageTag google_apis_playstore -Abi arm64-v8a
        $result.Name | Should -Be 'custom'
        $result.Device | Should -Be 'pixel_8'
        $result.SystemImage | Should -Be 'system-images;android-35;google_apis_playstore;arm64-v8a'
        $configuration = [IO.File]::ReadAllText((Join-Path $script:AvdHome 'custom.avd/config.ini'))
        $configuration | Should -Match '(?m)^hw.device.name=pixel_8\r?$'
        $configuration | Should -Match '(?m)^image.sysdir.1=system-images;android-35;google_apis_playstore;arm64-v8a\r?$'
    }

    It 'rejects an unavailable API for the selected image variant' {
        { New-WUAndroidEmulator -PlatformVersion 37 } | Should -Throw '*API 37*'
    }

    It 'rejects an unknown device' {
        { New-WUAndroidEmulator -Device missing } | Should -Throw '*profile was not found*'
    }

    It 'reports an empty device catalog without inventing a profile' {
        $script:DeviceCatalog = @()
        Write-TestAndroidTool
        { New-WUAndroidEmulator } | Should -Throw '*No standard Pixel*'
    }

    It 'reports an empty stable system image catalog' {
        $script:PackageCatalog = @()
        Write-TestAndroidTool
        { New-WUAndroidEmulator } | Should -Throw '*No stable Android system image*'
    }

    It 'preserves an existing AVD by default' {
        New-WUAndroidEmulator -Name custom -Device pixel_8 | Out-Null
        $configuration = Join-Path $script:AvdHome 'custom.avd/config.ini'
        $before = [IO.File]::ReadAllText($configuration)

        { New-WUAndroidEmulator -Name custom } | Should -Throw '*already exists*'

        [IO.File]::ReadAllText($configuration) | Should -Be $before
    }

    It 'replaces the existing device configuration only when Force is supplied' {
        New-WUAndroidEmulator -Name custom -Device pixel_8 | Out-Null

        New-WUAndroidEmulator -Name custom -Device pixel_10 -Force | Out-Null

        [IO.File]::ReadAllText((Join-Path $script:AvdHome 'custom.avd/config.ini')) | Should -Match '(?m)^hw.device.name=pixel_10\r?$'
    }

    It 'preserves Android SDK environment variables after creation' {
        $beforeAndroidHome = $env:ANDROID_HOME
        $beforeSdkRoot = $env:ANDROID_SDK_ROOT
        New-WUAndroidEmulator -Name restored
        $env:ANDROID_HOME | Should -Be $beforeAndroidHome
        $env:ANDROID_SDK_ROOT | Should -Be $beforeSdkRoot
    }

    It 'does not require installed SDK tools with WhatIf' {
        $env:Path = $script:ToolDirectory
        @(New-WUAndroidEmulator -WhatIf) | Should -HaveCount 0
        @(Get-ChildItem -LiteralPath $script:AvdHome) | Should -HaveCount 0
    }
}
