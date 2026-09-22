BeforeAll {
    . (Join-Path -Path $PSScriptRoot -ChildPath '../UnitTestBootstrap.ps1')
}

Describe 'Android component installation' {
    BeforeEach {
        $env:ANDROID_HOME = Join-Path $TestDrive 'android-sdk'
        New-Item -Path $env:ANDROID_HOME -ItemType Directory -Force | Out-Null
        Mock -CommandName Invoke-WUNativeCommand -ModuleName PSWinUtil -MockWith {
            [PSWinUtil.NativeCommandResult]::new($true, 0, '', '')
        }
    }

    It 'installs the requested emulator version' {
        Install-WUAndroidEmulator -Version '37.1.11'

        Should -Invoke -CommandName Invoke-WUNativeCommand -ModuleName PSWinUtil -Times 1 -Exactly -ParameterFilter {
            $Command -eq 'android.exe' -and $ArgumentList -contains 'emulator@37.1.11'
        }
    }

    It 'does not install the emulator with WhatIf' {
        Install-WUAndroidEmulator -Version '37.1.11' -WhatIf

        Should -Invoke -CommandName Invoke-WUNativeCommand -ModuleName PSWinUtil -Times 0 -Exactly
    }
}
