BeforeAll {
    . (Join-Path -Path $PSScriptRoot -ChildPath '../UnitTestBootstrap.ps1')
}

Describe 'Android AVD selection and errors' -Tag Android {
    BeforeEach {
        $script:OriginalAndroidHome = $env:ANDROID_HOME
        $script:OriginalSdkRoot = $env:ANDROID_SDK_ROOT
        $script:OriginalPath = $env:Path
        $script:ToolDirectory = Join-Path -Path $TestDrive -ChildPath 'android-tools'
        $script:SdkPath = Join-Path -Path $TestDrive -ChildPath 'sdk'
        $script:AvdManagerDirectory = Join-Path -Path $script:SdkPath -ChildPath 'cmdline-tools/latest/bin'
        New-Item -Path $script:AvdManagerDirectory -ItemType Directory -Force | Out-Null
        New-Item -Path $script:ToolDirectory -ItemType Directory -Force | Out-Null
        $script:DeviceCatalog = @('pixel_9', 'pixel_10', 'pixel_10_pro', 'pixel_tablet', 'pixel_8')
        $script:PackageCatalog = @(
            'system-images/android-9/google_apis/x86_64 1.0.0 older'
            'system-images/android-35/google_apis/x86_64 1.0.0 stable'
            'system-images/android-36/google_apis/x86_64 1.0.0 stable'
            'system-images/android-Z/google_apis/x86_64 1.0.0 preview'
            'system-images/android-37/google_apis/arm64-v8a 1.0.0 other ABI'
            'system-images/android-35/google_apis_playstore/arm64-v8a 1.0.0 Play'
        )
        $script:ExistingAvds = @()
        $script:InstallExitCode = 0
        Mock -CommandName Assert-WUPathProperty -ModuleName PSWinUtil
        function Write-TestAndroidTool {
            $deviceLines = $script:DeviceCatalog -join "`r`necho "
            $packageLines = $script:PackageCatalog -join "`r`necho "
            $avdLines = $script:ExistingAvds -join "`r`necho "
            $avdScript = "@echo off`r`nif `"%1`"==`"list`" if `"%2`"==`"device`" (`r`necho $deviceLines`r`nexit /b 0`r`n)`r`nif `"%1`"==`"list`" if `"%2`"==`"avd`" (`r`necho $avdLines`r`nexit /b 0`r`n)`r`nexit /b 0`r`n"
            [IO.File]::WriteAllText((Join-Path $script:AvdManagerDirectory 'avdmanager.bat'), $avdScript)
            $androidScript = "@echo off`r`nif `"%4`"==`"install`" exit /b $($script:InstallExitCode)`r`necho $packageLines`r`nexit /b 0`r`n"
            [IO.File]::WriteAllText((Join-Path $script:ToolDirectory 'android.cmd'), $androidScript)
        }
        Write-TestAndroidTool
        $env:Path = "$($script:ToolDirectory);$($script:OriginalPath)"
    }

    AfterEach {
        $env:ANDROID_HOME = $script:OriginalAndroidHome
        $env:ANDROID_SDK_ROOT = $script:OriginalSdkRoot
        $env:Path = $script:OriginalPath
    }

    It 'selects the newest standard Pixel and matching stable API numerically' {
        $result = New-WUAndroidEmulator -SdkPath $script:SdkPath
        $result.Name | Should -Be 'pixel_10_API_36'
        $result.Device | Should -Be 'pixel_10'
        $result.PlatformVersion | Should -Be 36
        $result.SystemImage | Should -Be 'system-images;android-36;google_apis;x86_64'
    }

    It 'honors explicit device, API, tag, ABI and name' {
        $result = New-WUAndroidEmulator -SdkPath $script:SdkPath -Name custom -Device pixel_8 -PlatformVersion 35 -SystemImageTag google_apis_playstore -Abi arm64-v8a
        $result.Name | Should -Be 'custom'
        $result.Device | Should -Be 'pixel_8'
        $result.SystemImage | Should -Be 'system-images;android-35;google_apis_playstore;arm64-v8a'
    }

    It 'rejects an unavailable API for the selected image variant' {
        { New-WUAndroidEmulator -SdkPath $script:SdkPath -PlatformVersion 37 } | Should -Throw '*API 37*'
    }

    It 'rejects an unknown device' {
        { New-WUAndroidEmulator -SdkPath $script:SdkPath -Device missing } | Should -Throw '*profile was not found*'
    }

    It 'reports an empty device catalog without inventing a profile' {
        $script:DeviceCatalog = @()
        Write-TestAndroidTool
        { New-WUAndroidEmulator -SdkPath $script:SdkPath } | Should -Throw '*No standard Pixel*'
    }

    It 'reports an empty stable system image catalog' {
        $script:PackageCatalog = @()
        Write-TestAndroidTool
        { New-WUAndroidEmulator -SdkPath $script:SdkPath } | Should -Throw '*No stable Android system image*'
    }

    It 'preserves an existing AVD by default' {
        $script:ExistingAvds = @('custom')
        Write-TestAndroidTool
        { New-WUAndroidEmulator -SdkPath $script:SdkPath -Name custom } | Should -Throw '*already exists*'
    }

    It 'restores SDK environment variables after creation' {
        $beforeAndroidHome = $env:ANDROID_HOME
        $beforeSdkRoot = $env:ANDROID_SDK_ROOT
        New-WUAndroidEmulator -SdkPath $script:SdkPath -Name restored
        $env:ANDROID_HOME | Should -Be $beforeAndroidHome
        $env:ANDROID_SDK_ROOT | Should -Be $beforeSdkRoot
    }

    It 'does not require installed SDK tools with WhatIf' {
        Remove-Item -LiteralPath $script:AvdManagerDirectory -Recurse -Force
        @(New-WUAndroidEmulator -SdkPath $script:SdkPath -WhatIf) | Should -HaveCount 0
    }
}
