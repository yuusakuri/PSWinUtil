BeforeAll {
    . (Join-Path -Path $PSScriptRoot -ChildPath '../UnitTestBootstrap.ps1')
}

Describe 'Android AVD selection and errors' -Tag Android {
    BeforeEach {
        $script:OriginalAndroidHome = $env:ANDROID_HOME
        $script:OriginalSdkRoot = $env:ANDROID_SDK_ROOT
        Mock -CommandName Assert-WUPathProperty -ModuleName PSWinUtil
        Mock -CommandName Invoke-WUAndroidSdkTool -ModuleName PSWinUtil -MockWith {
            param($ArgumentList)
            if ($ArgumentList -contains 'device') {
                'pixel_9', 'pixel_10', 'pixel_10_pro', 'pixel_tablet', 'pixel_8'
            } elseif ($ArgumentList -contains 'sdk' -and $ArgumentList -contains 'list') {
                'system-images/android-9/google_apis/x86_64 1.0.0 older'
                'system-images/android-35/google_apis/x86_64 1.0.0 stable'
                'system-images/android-36/google_apis/x86_64 1.0.0 stable'
                'system-images/android-Z/google_apis/x86_64 1.0.0 preview'
                'system-images/android-37/google_apis/arm64-v8a 1.0.0 other ABI'
                'system-images/android-35/google_apis_playstore/arm64-v8a 1.0.0 Play'
            }
        }
    }

    AfterEach {
        $env:ANDROID_HOME | Should -Be $script:OriginalAndroidHome
        $env:ANDROID_SDK_ROOT | Should -Be $script:OriginalSdkRoot
    }

    It 'selects the newest standard Pixel and matching stable API numerically' {
        $result = New-WUAndroidEmulator -SdkPath $TestDrive
        $result.Name | Should -Be 'pixel_10_API_36'
        $result.Device | Should -Be 'pixel_10'
        $result.PlatformVersion | Should -Be 36
        $result.SystemImage | Should -Be 'system-images;android-36;google_apis;x86_64'
    }

    It 'honors explicit device, API, tag, ABI and name' {
        $result = New-WUAndroidEmulator -SdkPath $TestDrive -Name custom -Device pixel_8 -PlatformVersion 35 -SystemImageTag google_apis_playstore -Abi arm64-v8a
        $result.Name | Should -Be 'custom'
        $result.Device | Should -Be 'pixel_8'
        $result.SystemImage | Should -Be 'system-images;android-35;google_apis_playstore;arm64-v8a'
    }

    It 'rejects an unavailable API for the selected image variant' {
        { New-WUAndroidEmulator -SdkPath $TestDrive -PlatformVersion 37 } | Should -Throw '*API 37*'
    }

    It 'rejects an unknown device' {
        { New-WUAndroidEmulator -SdkPath $TestDrive -Device missing } | Should -Throw '*profile was not found*'
    }

    It 'reports an empty device catalog without inventing a profile' {
        Mock -CommandName Invoke-WUAndroidSdkTool -ModuleName PSWinUtil -ParameterFilter { $ArgumentList -contains 'device' }
        { New-WUAndroidEmulator -SdkPath $TestDrive } | Should -Throw '*No standard Pixel*'
    }

    It 'reports an empty stable system image catalog' {
        Mock -CommandName Invoke-WUAndroidSdkTool -ModuleName PSWinUtil -ParameterFilter { $ArgumentList -contains 'sdk' -and $ArgumentList -contains 'list' }
        { New-WUAndroidEmulator -SdkPath $TestDrive } | Should -Throw '*No stable Android system image*'
    }

    It 'preserves an existing AVD by default' {
        Mock -CommandName Invoke-WUAndroidSdkTool -ModuleName PSWinUtil -ParameterFilter { $ArgumentList -contains 'list' -and $ArgumentList -contains 'avd' } -MockWith { 'custom' }
        { New-WUAndroidEmulator -SdkPath $TestDrive -Name custom } | Should -Throw '*already exists*'
    }

    It 'propagates installation errors and restores SDK environment variables' {
        Mock -CommandName Invoke-WUAndroidSdkTool -ModuleName PSWinUtil -ParameterFilter { $ArgumentList -contains 'install' } -MockWith { throw 'license not accepted' }
        { New-WUAndroidEmulator -SdkPath $TestDrive } | Should -Throw '*license not accepted*'
    }

    It 'does not require installed SDK tools with WhatIf' {
        Mock -CommandName Invoke-WUAndroidSdkTool -ModuleName PSWinUtil -MockWith { throw 'Tool must not run during preview' }
        @(New-WUAndroidEmulator -SdkPath $TestDrive -WhatIf) | Should -HaveCount 0
    }
}
