BeforeAll {
    . (Join-Path -Path $PSScriptRoot -ChildPath '../UnitTestBootstrap.ps1')
}

Describe 'Android SDK availability' {
    BeforeEach {
        $script:SavedAndroidHome = $env:ANDROID_HOME
        $script:SavedSdkRoot = $env:ANDROID_SDK_ROOT
        $script:SavedLocalAppData = $env:LOCALAPPDATA
        $script:SavedPath = $env:Path
        $fixture = Join-Path $TestDrive ([guid]::NewGuid().ToString('N'))
        $script:Sdk = Join-Path $fixture 'configured SDK'
        $env:LOCALAPPDATA = Join-Path $fixture 'LocalAppData'
        $script:OtherTools = Join-Path $fixture 'other SDK tools'
        New-Item -Path $script:OtherTools -ItemType Directory -Force | Out-Null
        [IO.File]::WriteAllText((Join-Path $script:OtherTools 'android.exe'), 'test command')
        $env:ANDROID_HOME = $script:Sdk
        $env:Path = $script:OtherTools
        $script:UserEnvironment = @{ Path = $script:OtherTools }
        $script:Downloads = @()
        $script:EmitPackageFiles = $true
        $script:InstallExitCode = 0
        $script:Catalog = @(
            'platforms/android-9 1.0.0 old'
            'platforms/android-35 2.0.0 stable'
            'platforms/android-36 2.0.0 stable'
            'platforms/android-37-beta1 1.0.0 preview'
            'build-tools/9.0.0 9.0.0 old'
            'build-tools/35.0.1 35.0.1 stable'
            'build-tools/36.0.0 36.0.0 stable'
            'build-tools/37.0.0-rc1 37.0.0-rc.1 preview'
        )
        Mock -CommandName Install-WUWingetPackage -ModuleName PSWinUtil
        Mock -CommandName Set-WUEnvironmentVariable -ModuleName PSWinUtil -MockWith {
            if ($Scope -contains 'User') {
                if ($null -eq $Value) {
                    $script:UserEnvironment.Remove($Name)
                } else {
                    $script:UserEnvironment[$Name] = $Value
                }
            }
            if ($Scope -contains 'Process') {
                [Environment]::SetEnvironmentVariable($Name, $Value, 'Process')
            }
        }
        Mock -CommandName Add-WUPathEnvironmentVariable -ModuleName PSWinUtil -MockWith {
            param($Path, $Scope, [switch]$Prepend)

            if ($Scope -contains 'User') {
                $paths = @($Path)
                if ($Prepend) {
                    $script:UserEnvironment.Path = ($paths -join ';') + ';' + $script:UserEnvironment.Path
                } else {
                    $script:UserEnvironment.Path += ';' + ($paths -join ';')
                }
            }
        }
        Mock -CommandName Update-WUProcessEnvironment -ModuleName PSWinUtil -MockWith {
            if ($script:UserEnvironment.ContainsKey('ANDROID_HOME')) {
                $env:ANDROID_HOME = $script:UserEnvironment.ANDROID_HOME
            }
            $env:Path = [Environment]::ExpandEnvironmentVariables($script:UserEnvironment.Path)
        }
        # Model downloaded package contents instead of asserting installer call sequences.
        Mock -CommandName Invoke-WUNativeCommand -ModuleName PSWinUtil -MockWith {
            $arguments = @($ArgumentList)
            if ($arguments -contains 'list') {
                return [PSWinUtil.NativeCommandResult]::new(
                    $true,
                    0,
                    ($script:Catalog -join [Environment]::NewLine),
                    ''
                )
            }
            $sdkRoot = $env:ANDROID_HOME
            foreach ($argument in $arguments) {
                $package = ($argument -split '@')[0]
                $revision = ($argument -split '@')[1]
                $files = @()
                if ($package -eq 'platform-tools') {
                    $directory = Join-Path $sdkRoot 'platform-tools'
                    $files = @('adb.exe')
                    if (-not $revision) { $revision = '37.0.1' }
                } elseif ($package -eq 'emulator') {
                    $directory = Join-Path $sdkRoot 'emulator'
                    $files = @('emulator.exe')
                    if (-not $revision) { $revision = '37.1.11' }
                } elseif ($package -match '^platforms/android-([0-9]+)$') {
                    $directory = Join-Path $sdkRoot "platforms/android-$($Matches[1])"
                    $files = @('android.jar')
                    if (-not $revision) { $revision = '2.0.0' }
                } elseif ($package -match '^build-tools/([0-9]+\.[0-9]+\.[0-9]+)$') {
                    $directory = Join-Path $sdkRoot "build-tools/$($Matches[1])"
                    $files = @('aapt2.exe')
                    $revision = $Matches[1]
                } elseif ($package -match '^cmdline-tools/(latest|[0-9]+\.[0-9]+)$') {
                    $directory = Join-Path $sdkRoot "cmdline-tools/$($Matches[1])"
                    $files = @('bin/sdkmanager.bat', 'bin/avdmanager.bat')
                    $revision = if ($Matches[1] -eq 'latest') { '23.0.0' } else { $Matches[1] + '.0' }
                } else {
                    continue
                }
                $script:Downloads += $package
                New-Item -Path $directory -ItemType Directory -Force | Out-Null
                if (-not $script:EmitPackageFiles) {
                    continue
                }
                foreach ($file in $files) {
                    $destination = Join-Path $directory $file
                    New-Item -Path (Split-Path $destination -Parent) -ItemType Directory -Force | Out-Null
                    [IO.File]::WriteAllText($destination, "package $package")
                }
            }
            [PSWinUtil.NativeCommandResult]::new(
                ($script:InstallExitCode -eq 0),
                $script:InstallExitCode,
                '',
                ''
            )
        }
    }

    AfterEach {
        $env:ANDROID_HOME = $script:SavedAndroidHome
        $env:ANDROID_SDK_ROOT = $script:SavedSdkRoot
        $env:LOCALAPPDATA = $script:SavedLocalAppData
        $env:Path = $script:SavedPath
    }

    It 'makes the latest stable SDK usable in the configured location' {
        $result = Install-WUAndroidSdk

        $result.FullName | Should -Be $script:Sdk
        [IO.File]::ReadAllText((Join-Path $script:Sdk 'platforms/android-36/android.jar')) | Should -Be 'package platforms/android-36'
        [IO.File]::ReadAllText((Join-Path $script:Sdk 'build-tools/latest/aapt2.exe')) | Should -Be 'package build-tools/36.0.0'
        $script:UserEnvironment.ANDROID_HOME | Should -Be $script:Sdk
        foreach ($command in @('adb.exe', 'aapt2.exe', 'emulator.exe', 'avdmanager.bat')) {
            Test-WUCommand -Name $command | Should -BeTrue
        }
    }

    It 'returns all stable package versions or only the latest version' {
        InModuleScope -ModuleName PSWinUtil {
            Get-WUAndroidSdkPackageVersion -Component Platform
        } | Should -Be @('36', '35', '9')

        InModuleScope -ModuleName PSWinUtil {
            Get-WUAndroidSdkPackageVersion -Component BuildTools -Latest
        } | Should -Be '36.0.0'
    }

    It 'installs into the standard Windows SDK location when ANDROID_HOME is unset' {
        $env:ANDROID_HOME = $null
        $expectedPath = Join-Path $env:LOCALAPPDATA 'Android\Sdk'

        $result = Install-WUAndroidSdk

        $result.FullName | Should -Be $expectedPath
        $env:ANDROID_HOME | Should -Be $expectedPath
        $script:UserEnvironment.ANDROID_HOME | Should -Be $expectedPath
        Test-Path -LiteralPath (Join-Path $expectedPath 'platforms/android-36/android.jar') | Should -BeTrue
        Test-Path -LiteralPath (Join-Path $expectedPath 'cmdline-tools/latest/bin/avdmanager.bat') | Should -BeTrue
    }

    It 'makes a requested API and Build Tools version usable' {
        Install-WUAndroidSdk -PlatformVersion 35 -BuildToolsVersion '35.0.1' | Out-Null

        [IO.File]::ReadAllText((Join-Path $script:Sdk 'platforms/android-35/android.jar')) | Should -Be 'package platforms/android-35'
        [IO.File]::ReadAllText((Join-Path $script:Sdk 'build-tools/latest/aapt2.exe')) | Should -Be 'package build-tools/35.0.1'
    }

    It 'preserves existing SDK data without downloading installed components again' {
        Install-WUAndroidSdk -PlatformVersion 36 -BuildToolsVersion '36.0.0' | Out-Null
        $adb = Join-Path $script:Sdk 'platform-tools/adb.exe'
        [IO.File]::WriteAllText($adb, 'existing SDK data')
        $script:Downloads = @()

        Install-WUAndroidSdk -PlatformVersion 36 -BuildToolsVersion '36.0.0' | Out-Null

        [IO.File]::ReadAllText($adb) | Should -Be 'existing SDK data'
        $script:Downloads | Should -HaveCount 0
    }

    It 'restores a missing SDK component while preserving the others' -TestCases @(
        @{ MissingPath = 'platform-tools/adb.exe' }
        @{ MissingPath = 'platforms/android-36/android.jar' }
        @{ MissingPath = 'build-tools/36.0.0/aapt2.exe' }
        @{ MissingPath = 'emulator/emulator.exe' }
        @{ MissingPath = 'cmdline-tools/latest/bin/sdkmanager.bat' }
    ) {
        param($MissingPath)

        Install-WUAndroidSdk -PlatformVersion 36 -BuildToolsVersion '36.0.0' | Out-Null
        $missingFile = Join-Path $script:Sdk $MissingPath
        $keptFile = Join-Path $script:Sdk 'unrelated-project.txt'
        [IO.File]::WriteAllText($keptFile, 'keep project settings')
        Remove-Item -LiteralPath $missingFile

        Install-WUAndroidSdk -PlatformVersion 36 -BuildToolsVersion '36.0.0' | Out-Null

        Test-Path -LiteralPath $missingFile | Should -BeTrue
        [IO.File]::ReadAllText($keptFile) | Should -Be 'keep project settings'
    }

    It 'leaves SDK files and environment settings unchanged when previewing installation' {
        $env:ANDROID_HOME = $null
        $defaultSdkPath = Join-Path $env:LOCALAPPDATA 'Android\Sdk'
        $beforePath = $env:Path
        $env:ANDROID_SDK_ROOT = 'old process SDK'
        $script:UserEnvironment.ANDROID_SDK_ROOT = 'old user SDK'
        Install-WUAndroidSdk -WhatIf

        Test-Path -LiteralPath $defaultSdkPath | Should -BeFalse
        $script:UserEnvironment.ContainsKey('ANDROID_HOME') | Should -BeFalse
        $env:ANDROID_HOME | Should -BeNullOrEmpty
        $env:Path | Should -Be $beforePath
        $script:Downloads | Should -HaveCount 0
        $env:ANDROID_SDK_ROOT | Should -Be 'old process SDK'
        $script:UserEnvironment.ANDROID_SDK_ROOT | Should -Be 'old user SDK'
    }

    It 'uses ANDROID_HOME without a conflicting deprecated SDK root after installation' {
        $env:ANDROID_SDK_ROOT = 'old process SDK'
        $script:UserEnvironment.ANDROID_SDK_ROOT = 'old user SDK'

        $result = Install-WUAndroidSdk

        $result.FullName | Should -Be $script:Sdk
        $env:ANDROID_HOME | Should -Be $script:Sdk
        $script:UserEnvironment.ANDROID_HOME | Should -Be $script:Sdk
        $env:ANDROID_SDK_ROOT | Should -BeNullOrEmpty
        $script:UserEnvironment.ContainsKey('ANDROID_SDK_ROOT') | Should -BeFalse
    }

    It 'uses available tools from another SDK without requiring duplicate executables' {
        $script:EmitPackageFiles = $false
        foreach ($command in @('adb.exe', 'aapt2.exe', 'emulator.exe', 'avdmanager.bat')) {
            [IO.File]::WriteAllText((Join-Path $script:OtherTools $command), 'existing tools')
        }

        $result = Install-WUAndroidSdk -PlatformVersion 36 -BuildToolsVersion '36.0.0'

        $result.FullName | Should -Be $script:Sdk
        foreach ($command in @('adb.exe', 'aapt2.exe', 'emulator.exe', 'avdmanager.bat')) {
            Test-WUCommand -Name $command | Should -BeTrue
        }
    }

    It 'reports an unavailable emulator instead of returning a usable SDK' {
        $script:EmitPackageFiles = $false
        foreach ($command in @('adb.exe', 'aapt2.exe', 'avdmanager.bat')) {
            [IO.File]::WriteAllText((Join-Path $script:OtherTools $command), 'existing tools')
        }

        { Install-WUAndroidSdk -PlatformVersion 36 -BuildToolsVersion '36.0.0' } | Should -Throw '*emulator.exe*not available*'
    }

    It 'does not overwrite an unrelated latest directory' {
        $latest = Join-Path $script:Sdk 'build-tools/latest'
        New-Item -Path $latest -ItemType Directory -Force | Out-Null
        $keptFile = Join-Path $latest 'project.txt'
        [IO.File]::WriteAllText($keptFile, 'keep this directory')

        { Install-WUAndroidSdk -PlatformVersion 36 -BuildToolsVersion '36.0.0' } | Should -Throw '*not a directory junction*'

        [IO.File]::ReadAllText($keptFile) | Should -Be 'keep this directory'
    }

    It 'reports an unavailable stable SDK before downloading components' -TestCases @(
        @{ Catalog = @('platforms/android-37-beta1 1.0.0 preview') }
        @{ Catalog = @('platforms/android-36 2.0.0 stable', 'build-tools/37.0.0-rc1 37.0.0-rc.1 preview') }
    ) {
        param($Catalog)

        $script:Catalog = $Catalog

        { Install-WUAndroidSdk } | Should -Throw '*No stable*'

        Test-Path -LiteralPath $script:Sdk | Should -BeFalse
        $script:UserEnvironment.ANDROID_HOME | Should -Be $script:Sdk
    }
}
