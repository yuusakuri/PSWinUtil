BeforeAll {
    . (Join-Path -Path $PSScriptRoot -ChildPath '../UnitTestBootstrap.ps1')
}

Describe 'Android SDK process error integration' -Tag Android {
    It 'reports a missing SDK tool without creating an AVD' {
        { New-WUAndroidEmulator -SdkPath $TestDrive } | Should -Throw
    }

    It 'preserves native stderr diagnostics and the exit code under ErrorAction Stop' {
        $sdk = Join-Path $TestDrive 'sdk with spaces'
        $bin = Join-Path $sdk 'cmdline-tools/latest/bin'
        New-Item -Path $bin -ItemType Directory -Force | Out-Null
        # A controlled failing native dependency exercises Windows process I/O.
        # The real SDK contract is checked separately by NewAndroidEmulator.Tests.ps1.
        [IO.File]::WriteAllText((Join-Path $bin 'avdmanager.bat'), "@echo off`r`necho SDK diagnostic 1>&2`r`nexit /b 23`r`n")
        $savedAndroidHome = $env:ANDROID_HOME
        $savedSdkRoot = $env:ANDROID_SDK_ROOT
        { New-WUAndroidEmulator -SdkPath $sdk -ErrorAction Stop } | Should -Throw '*exit code 23*SDK diagnostic*'
        $env:ANDROID_HOME | Should -Be $savedAndroidHome
        $env:ANDROID_SDK_ROOT | Should -Be $savedSdkRoot
    }
}
