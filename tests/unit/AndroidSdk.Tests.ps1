BeforeAll {
    . (Join-Path -Path $PSScriptRoot -ChildPath '../UnitTestBootstrap.ps1')
    $script:Module = Get-Module -Name 'PSWinUtil' -ErrorAction Stop
    $script:AndroidCommandWasPresent = $null -ne (Get-Command -Name 'android.exe' -ErrorAction SilentlyContinue)
    if (-not $script:AndroidCommandWasPresent) {
        Set-Item -Path Function:\global:android.exe -Value { }
    }
}

AfterAll {
    if (-not $script:AndroidCommandWasPresent) {
        Remove-Item -Path Function:\global:android.exe -ErrorAction SilentlyContinue
    }
}

Describe 'Get-WUAndroidPlatformVersion' {
    BeforeAll {
        $script:PackageList = @(
            '  build-tools/35.0.1  35.0.1  Android SDK Build-Tools 35.0.1'
            '  build-tools/36.0.0  36.0.0  Android SDK Build-Tools 36'
            '  build-tools/37.0.0-rc1  37.0.0-rc.1  Android SDK Build-Tools 37 rc1'
            '  platforms/android-35  2.0.0  Android SDK Platform 35'
            '  platforms/android-36  2.0.0  Android SDK Platform 36'
            '  platforms/android-36.1  1.0.0  Android SDK Platform 36.1'
            '  platforms/android-37-beta1  1.0.0  Android SDK Platform Preview'
        )
    }

    It 'selects the greatest integer platform API level' {
        $result = & $script:Module {
            param($PackageList)

            Get-WUAndroidPlatformVersion -InputObject $PackageList
        } $script:PackageList

        $result | Should -Be '36'
    }

    It 'rejects a package list without a stable candidate' {
        {
            & $script:Module {
                Get-WUAndroidPlatformVersion `
                    -InputObject 'platforms/android-37-beta1  1.0.0'
            }
        } | Should -Throw '*No stable*'
    }
}

Describe 'Get-WUAndroidBuildToolsVersion' {
    BeforeAll {
        $script:PackageList = @(
            '  build-tools/35.0.1  35.0.1  Android SDK Build-Tools 35.0.1'
            '  build-tools/36.0.0  36.0.0  Android SDK Build-Tools 36'
            '  build-tools/37.0.0-rc1  37.0.0-rc.1  Android SDK Build-Tools 37 rc1'
        )
    }

    It 'selects the greatest stable three-part Build Tools version' {
        $result = & $script:Module {
            param($PackageList)

            Get-WUAndroidBuildToolsVersion -InputObject $PackageList
        } $script:PackageList

        $result | Should -Be '36.0.0'
    }

    It 'rejects a package list without a stable candidate' {
        {
            & $script:Module {
                Get-WUAndroidBuildToolsVersion `
                    -InputObject 'build-tools/37.0.0-rc1  37.0.0-rc.1'
            }
        } | Should -Throw '*No stable*'
    }
}

Describe 'Set-WUAndroidBuildToolsLatest' {
    BeforeEach {
        $script:BuildToolsPath = Join-Path -Path $TestDrive -ChildPath 'build-tools'
        Remove-Item -LiteralPath $script:BuildToolsPath -Recurse -Force -ErrorAction Ignore
    }

    It 'creates and updates the latest directory junction' -Skip:($env:OS -ne 'Windows_NT') {
        $firstVersionPath = Join-Path -Path $script:BuildToolsPath -ChildPath '35.0.0'
        $secondVersionPath = Join-Path -Path $script:BuildToolsPath -ChildPath '36.0.0'
        New-Item -Path $firstVersionPath -ItemType Directory -Force | Out-Null
        New-Item -Path $secondVersionPath -ItemType Directory -Force | Out-Null

        & $script:Module {
            param($BuildToolsPath)

            Set-WUAndroidBuildToolsLatest -BuildToolsPath $BuildToolsPath -Version '35.0.0'
            Set-WUAndroidBuildToolsLatest -BuildToolsPath $BuildToolsPath -Version '36.0.0'
        } $script:BuildToolsPath

        $latestPath = Join-Path -Path $script:BuildToolsPath -ChildPath 'latest'
        $latest = Get-Item -LiteralPath $latestPath -Force
        $latest.Attributes -band [System.IO.FileAttributes]::ReparsePoint | Should -Not -Be 0
        & $script:Module {
            param($ReferencePath, $DifferencePath)

            Compare-WUPath -ReferencePath $ReferencePath -DifferencePath $DifferencePath
        } $secondVersionPath ([string]@($latest.Target)[0]) | Should -BeTrue
    }

    It 'preserves an ordinary latest directory' {
        $versionPath = Join-Path -Path $script:BuildToolsPath -ChildPath '36.0.0'
        $latestPath = Join-Path -Path $script:BuildToolsPath -ChildPath 'latest'
        New-Item -Path $versionPath -ItemType Directory -Force | Out-Null
        New-Item -Path $latestPath -ItemType Directory -Force | Out-Null

        {
            & $script:Module {
                param($BuildToolsPath)

                Set-WUAndroidBuildToolsLatest -BuildToolsPath $BuildToolsPath -Version '36.0.0'
            } $script:BuildToolsPath
        } | Should -Throw '*not a directory junction*'

        Test-Path -LiteralPath $latestPath | Should -BeTrue
    }
}

Describe 'Install-WUAndroidSdk' {
    BeforeEach {
        $script:SdkPath = Join-Path -Path $TestDrive -ChildPath 'AndroidSdk'
        $script:AndroidCalls = @()
        Remove-Item -LiteralPath $script:SdkPath -Recurse -Force -ErrorAction Ignore

        Mock -CommandName Install-WUWingetPackage -ModuleName PSWinUtil
        Mock -CommandName Update-WUProcessEnvironment -ModuleName PSWinUtil
        Mock -CommandName android.exe -ModuleName PSWinUtil -MockWith {
            $global:LASTEXITCODE = 0
            $androidArguments = @($args)
            $script:AndroidCalls += , $androidArguments
            if ($androidArguments -contains 'list') {
                if ($androidArguments -contains 'platforms/android-*') {
                    return @(
                        '  platforms/android-35  2.0.0  Android SDK Platform 35'
                        '  platforms/android-36  2.0.0  Android SDK Platform 36'
                        '  platforms/android-37-beta1  1.0.0  Android SDK Platform Preview'
                    )
                }
                return @(
                    '  build-tools/35.0.1  35.0.1  Android SDK Build-Tools 35.0.1'
                    '  build-tools/36.0.0  36.0.0  Android SDK Build-Tools 36'
                    '  build-tools/37.0.0-rc1  37.0.0-rc.1  Android SDK Build-Tools 37 rc1'
                )
            }

            foreach ($argument in $androidArguments) {
                if ($argument -eq 'platform-tools') {
                    $file = Join-Path -Path $script:SdkPath -ChildPath 'platform-tools\adb.exe'
                } elseif ($argument -match '^platforms/android-(\d+)$') {
                    $file = Join-Path -Path $script:SdkPath -ChildPath "platforms\android-$($Matches[1])\android.jar"
                } elseif ($argument -match '^build-tools/([0-9]+\.[0-9]+\.[0-9]+)$') {
                    $file = Join-Path -Path $script:SdkPath -ChildPath "build-tools\$($Matches[1])\aapt2.exe"
                } elseif ($argument -eq 'emulator') {
                    $file = Join-Path -Path $script:SdkPath -ChildPath 'emulator\emulator.exe'
                } elseif ($argument -eq 'cmdline-tools/latest') {
                    $file = Join-Path -Path $script:SdkPath -ChildPath 'cmdline-tools\latest\bin\sdkmanager.bat'
                    $avdManager = Join-Path -Path $script:SdkPath -ChildPath 'cmdline-tools\latest\bin\avdmanager.bat'
                    New-Item -Path (Split-Path -Path $file -Parent) -ItemType Directory -Force | Out-Null
                    [System.IO.File]::WriteAllText($file, '')
                    [System.IO.File]::WriteAllText($avdManager, '')
                    continue
                } else {
                    continue
                }
                New-Item -Path (Split-Path -Path $file -Parent) -ItemType Directory -Force | Out-Null
                [System.IO.File]::WriteAllText($file, '')
            }
        }
        Mock -CommandName Set-WUAndroidBuildToolsLatest -ModuleName PSWinUtil
        Mock -CommandName Set-WUEnvironmentVariable -ModuleName PSWinUtil
        Mock -CommandName Add-WUPathEnvironmentVariable -ModuleName PSWinUtil
    }

    It 'resolves and installs the latest stable package versions' {
        $result = Install-WUAndroidSdk -SdkPath $script:SdkPath

        $result | Should -BeOfType ([System.IO.DirectoryInfo])
        $script:AndroidCalls.Count | Should -Be 3
        foreach ($androidCall in $script:AndroidCalls) {
            $androidCall -contains '--no-metrics' | Should -BeTrue
            $androidCall -contains "--sdk=$script:SdkPath" | Should -BeTrue
        }
        $script:AndroidCalls[0] -contains 'platforms/android-*' | Should -BeTrue
        $script:AndroidCalls[1] -contains 'build-tools/*' | Should -BeTrue
        $script:AndroidCalls[2] -contains 'platform-tools' | Should -BeTrue
        $script:AndroidCalls[2] -contains 'platforms/android-36' | Should -BeTrue
        $script:AndroidCalls[2] -contains 'build-tools/36.0.0' | Should -BeTrue
        $script:AndroidCalls[2] -contains 'emulator' | Should -BeTrue
        $script:AndroidCalls[2] -contains 'cmdline-tools/latest' | Should -BeTrue
        Should -Invoke -CommandName Set-WUAndroidBuildToolsLatest -ModuleName PSWinUtil -Times 1 -Exactly -ParameterFilter {
            $Version -eq '36.0.0'
        }
    }

    It 'maps explicit versions without listing available packages' {
        Install-WUAndroidSdk `
            -SdkPath $script:SdkPath `
            -PlatformVersion 35 `
            -BuildToolsVersion '35.0.1'

        $script:AndroidCalls.Count | Should -Be 1
        $script:AndroidCalls[0] -contains 'platforms/android-35' | Should -BeTrue
        $script:AndroidCalls[0] -contains 'build-tools/35.0.1' | Should -BeTrue
    }

    It 'does not reinstall components that are already present' {
        $requiredPaths = @(
            'platform-tools\adb.exe'
            'platforms\android-36\android.jar'
            'build-tools\36.0.0\aapt2.exe'
            'emulator\emulator.exe'
            'cmdline-tools\latest\bin\sdkmanager.bat'
            'cmdline-tools\latest\bin\avdmanager.bat'
        )
        foreach ($requiredPath in $requiredPaths) {
            $fullPath = Join-Path -Path $script:SdkPath -ChildPath $requiredPath
            New-Item -Path (Split-Path -Path $fullPath -Parent) -ItemType Directory -Force | Out-Null
            [System.IO.File]::WriteAllText($fullPath, '')
        }

        Install-WUAndroidSdk `
            -SdkPath $script:SdkPath `
            -PlatformVersion 36 `
            -BuildToolsVersion '36.0.0'

        $script:AndroidCalls.Count | Should -Be 0
    }

    It 'installs only the missing SDK package' -TestCases @(
        @{ MissingPath = 'platform-tools\adb.exe'; Package = 'platform-tools' }
        @{ MissingPath = 'platforms\android-36\android.jar'; Package = 'platforms/android-36' }
        @{ MissingPath = 'build-tools\36.0.0\aapt2.exe'; Package = 'build-tools/36.0.0' }
        @{ MissingPath = 'emulator\emulator.exe'; Package = 'emulator' }
        @{ MissingPath = 'cmdline-tools\latest\bin\sdkmanager.bat'; Package = 'cmdline-tools/latest' }
    ) {
        param($MissingPath, $Package)

        $script:ExpectedPackage = $Package
        $requiredPaths = @(
            'platform-tools\adb.exe'
            'platforms\android-36\android.jar'
            'build-tools\36.0.0\aapt2.exe'
            'emulator\emulator.exe'
            'cmdline-tools\latest\bin\sdkmanager.bat'
            'cmdline-tools\latest\bin\avdmanager.bat'
        )
        foreach ($requiredPath in $requiredPaths) {
            if ($requiredPath -eq $MissingPath) {
                continue
            }
            $fullPath = Join-Path -Path $script:SdkPath -ChildPath $requiredPath
            New-Item -Path (Split-Path -Path $fullPath -Parent) -ItemType Directory -Force | Out-Null
            [System.IO.File]::WriteAllText($fullPath, '')
        }

        Install-WUAndroidSdk `
            -SdkPath $script:SdkPath `
            -PlatformVersion 36 `
            -BuildToolsVersion '36.0.0'

        $script:AndroidCalls.Count | Should -Be 1
        @($script:AndroidCalls[0] | Where-Object { $_ -eq $script:ExpectedPackage }).Count | Should -Be 1
    }

    It 'sets ANDROID_HOME and adds SDK directories to persistent and process PATH values' {
        Install-WUAndroidSdk `
            -SdkPath $script:SdkPath `
            -PlatformVersion 36 `
            -BuildToolsVersion '36.0.0'

        Should -Invoke -CommandName Install-WUWingetPackage -ModuleName PSWinUtil -Times 1 -Exactly -ParameterFilter {
            $Id -eq 'Google.AndroidCLI' -and -not $WhatIf
        }
        Should -Invoke -CommandName Set-WUEnvironmentVariable -ModuleName PSWinUtil -Times 1 -Exactly -ParameterFilter {
            $Name -eq 'ANDROID_HOME' -and
            $Value -eq $script:SdkPath -and
            $Scope -contains 'User' -and
            $Scope -contains 'Process'
        }
        Should -Invoke -CommandName Add-WUPathEnvironmentVariable -ModuleName PSWinUtil -Times 1 -Exactly -ParameterFilter {
            $Scope -eq 'User' -and
            $Path -contains '%ANDROID_HOME%\platform-tools' -and
            $Path -contains '%ANDROID_HOME%\emulator' -and
            $Path -contains '%ANDROID_HOME%\build-tools\latest' -and
            $Path -contains '%ANDROID_HOME%\cmdline-tools\latest\bin'
        }
        Should -Invoke -CommandName Add-WUPathEnvironmentVariable -ModuleName PSWinUtil -Times 1 -Exactly -ParameterFilter {
            $Scope -eq 'Process' -and
            $Path -contains (Join-Path -Path $script:SdkPath -ChildPath 'platform-tools') -and
            $Path -contains (Join-Path -Path $script:SdkPath -ChildPath 'emulator') -and
            $Path -contains (Join-Path -Path $script:SdkPath -ChildPath 'cmdline-tools\latest\bin')
        }
    }

    It 'does not start the installation with WhatIf' {
        Install-WUAndroidSdk -SdkPath $script:SdkPath -WhatIf

        Should -Invoke -CommandName Install-WUWingetPackage -ModuleName PSWinUtil -Times 0 -Exactly
        $script:AndroidCalls.Count | Should -Be 0
        Should -Invoke -CommandName Set-WUEnvironmentVariable -ModuleName PSWinUtil -Times 0 -Exactly
        Should -Invoke -CommandName Add-WUPathEnvironmentVariable -ModuleName PSWinUtil -Times 0 -Exactly
    }
}
