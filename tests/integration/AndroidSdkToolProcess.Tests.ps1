BeforeAll {
    . (Join-Path -Path $PSScriptRoot -ChildPath '../UnitTestBootstrap.ps1')
}

Describe 'Android SDK process error integration' -Tag Android {
    It 'reports a missing SDK tool without creating an AVD' {
        $savedPath = $env:Path
        $env:Path = $TestDrive
        try {
            { New-WUAndroidEmulator } | Should -Throw
        } finally {
            $env:Path = $savedPath
        }
    }

    It 'preserves native stderr diagnostics and the exit code under ErrorAction Stop' {
        $sdk = Join-Path $TestDrive 'sdk with spaces'
        $bin = Join-Path $sdk 'cmdline-tools/latest/bin'
        New-Item -Path $bin -ItemType Directory -Force | Out-Null
        # A controlled failing native dependency exercises Windows process I/O.
        # The real SDK contract is checked separately by NewAndroidEmulator.Tests.ps1.
        [IO.File]::WriteAllText((Join-Path $bin 'avdmanager.bat'), "@echo off`r`necho SDK diagnostic 1>&2`r`nexit /b 23`r`n")
        [IO.File]::WriteAllText((Join-Path $bin 'android.cmd'), "@echo off`r`nexit /b 0`r`n")
        $savedPath = $env:Path
        $env:Path = $bin
        $savedAndroidHome = $env:ANDROID_HOME
        $savedSdkRoot = $env:ANDROID_SDK_ROOT
        try {
            { New-WUAndroidEmulator -ErrorAction Stop } | Should -Throw '*exit code 23*SDK diagnostic*'
            $env:ANDROID_HOME | Should -Be $savedAndroidHome
            $env:ANDROID_SDK_ROOT | Should -Be $savedSdkRoot
        } finally {
            $env:Path = $savedPath
        }
    }
}
