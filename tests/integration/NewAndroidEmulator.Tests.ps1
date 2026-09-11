$runAndroidIntegration = $env:PSWINUTIL_RUN_ANDROID_INTEGRATION -eq '1'

BeforeAll {
    . (Join-Path -Path $PSScriptRoot -ChildPath '../UnitTestBootstrap.ps1')
}

Describe 'Android SDK AVD integration and CLI contract' -Tag Android -Skip:(-not $runAndroidIntegration) {
    BeforeAll {
        if ([string]::IsNullOrWhiteSpace($env:PSWINUTIL_ANDROID_TEST_SDK)) {
            throw 'Set PSWINUTIL_ANDROID_TEST_SDK to a prepared SDK with Command-Line Tools and accepted licenses.'
        }
        $script:SavedAvdHome = $env:ANDROID_AVD_HOME
        $script:SavedPath = $env:Path
        $emulatorPath = Join-Path $env:PSWINUTIL_ANDROID_TEST_SDK 'emulator'
        $platformToolsPath = Join-Path $env:PSWINUTIL_ANDROID_TEST_SDK 'platform-tools'
        $env:Path = $emulatorPath + ';' + $platformToolsPath + ';' + $env:Path
        $script:AvdHome = Join-Path $TestDrive 'isolated avds'
        New-Item -Path $script:AvdHome -ItemType Directory | Out-Null
        $env:ANDROID_AVD_HOME = $script:AvdHome
    }

    AfterAll {
        $env:ANDROID_AVD_HOME = $script:SavedAvdHome
        $env:Path = $script:SavedPath
    }

    It 'creates a real AVD using the selected image and newest installed Pixel profile' {
        $result = New-WUAndroidEmulator -SdkPath $env:PSWINUTIL_ANDROID_TEST_SDK -Name contract_device -PlatformVersion 29 -SystemImageTag default
        $result.Name | Should -Be 'contract_device'
        $result.Device | Should -Match '^pixel_[0-9]+$'
        $config = [IO.File]::ReadAllText((Join-Path $script:AvdHome 'contract_device.avd/config.ini'))
        $config | Should -Match ('(?m)^hw.device.name=' + [regex]::Escape($result.Device) + '\r?$')
        $config | Should -Match '(?m)^image.sysdir.1=system-images[\\/]android-29[\\/]default[\\/]x86_64[\\/]?\r?$'
        $config | Should -Match '(?m)^abi.type=x86_64\r?$'
        [IO.File]::ReadAllText((Join-Path $script:AvdHome 'contract_device.ini')) |
            Should -Match '(?m)^target=android-29\r?$'
        @(Get-WUAndroidEmulator) | Should -Contain 'contract_device'
    }

    It 'rejects duplicate names without overwriting an existing configuration' {
        $parameters = @{ SdkPath = $env:PSWINUTIL_ANDROID_TEST_SDK; Name = 'duplicate'; Device = 'pixel_8'; PlatformVersion = 29; SystemImageTag = 'default' }
        New-WUAndroidEmulator @parameters | Out-Null
        $configPath = Join-Path $script:AvdHome 'duplicate.avd/config.ini'
        $before = [IO.File]::ReadAllText($configPath)
        { New-WUAndroidEmulator @parameters } | Should -Throw '*already exists*'
        [IO.File]::ReadAllText($configPath) | Should -Be $before
        $parameters.Device = 'pixel_9'
        New-WUAndroidEmulator @parameters -Force | Out-Null
        [IO.File]::ReadAllText($configPath) | Should -Match '(?m)^hw.device.name=pixel_9\r?$'
    }

    It 'leaves the isolated AVD home unchanged with WhatIf' {
        New-WUAndroidEmulator -SdkPath $env:PSWINUTIL_ANDROID_TEST_SDK -Name preview -WhatIf
        Test-Path -LiteralPath (Join-Path $script:AvdHome 'preview.ini') | Should -BeFalse
    }

    It 'previews startup without launching the created AVD' {
        New-WUAndroidEmulator -SdkPath $env:PSWINUTIL_ANDROID_TEST_SDK -Name startup_preview -PlatformVersion 29 -SystemImageTag default | Out-Null
        @(Start-WUAndroidEmulator -Name startup_preview -WhatIf) | Should -HaveCount 0
        @(Get-WUAndroidEmulator) | Should -Contain 'startup_preview'
    }
}
