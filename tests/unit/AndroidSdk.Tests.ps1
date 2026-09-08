BeforeAll {
    . (Join-Path -Path $PSScriptRoot -ChildPath '../UnitTestBootstrap.ps1')
    $script:Module = Get-Module -Name 'PSWinUtil' -ErrorAction Stop
}

Describe 'Resolve-WUAndroidSdkPackageVersion' {
    BeforeAll {
        $script:PackageList = @(
            '  build-tools;35.0.1 | 35.0.1 | Android SDK Build-Tools 35.0.1'
            '  build-tools;36.0.0 | 36.0.0 | Android SDK Build-Tools 36'
            '  build-tools;37.0.0-rc1 | 37.0.0 rc1 | Android SDK Build-Tools 37 rc1'
            '  platforms;android-35 | 2 | Android SDK Platform 35'
            '  platforms;android-36 | 1 | Android SDK Platform 36'
            '  platforms;android-37-preview | 1 | Android SDK Platform Preview'
        )
    }

    It 'selects the greatest numeric platform API level' {
        $result = & $script:Module {
            param($PackageList)

            Resolve-WUAndroidSdkPackageVersion `
                -InputObject $PackageList `
                -PackageType Platform
        } $script:PackageList

        $result | Should -Be '36'
    }

    It 'selects the greatest stable three-part Build Tools version' {
        $result = & $script:Module {
            param($PackageList)

            Resolve-WUAndroidSdkPackageVersion `
                -InputObject $PackageList `
                -PackageType BuildTools
        } $script:PackageList

        $result | Should -Be '36.0.0'
    }

    It 'rejects a package list without a stable candidate' {
        {
            & $script:Module {
                Resolve-WUAndroidSdkPackageVersion `
                    -InputObject 'build-tools;37.0.0-rc1 | preview' `
                    -PackageType BuildTools
            }
        } | Should -Throw '*No stable*'
    }
}

Describe 'Invoke-WUAndroidSdkManager' {
    BeforeEach {
        $script:SdkManagerPath = Join-Path -Path $TestDrive -ChildPath 'sdkmanager.bat'
    }

    It 'accepts native stderr with ErrorAction Stop when the command succeeds' -Skip:($env:OS -ne 'Windows_NT') {
        [System.IO.File]::WriteAllLines(
            $script:SdkManagerPath,
            @('@echo off', 'echo sdk warning 1>&2', 'exit /b 0')
        )

        {
            & $script:Module {
                param($SdkManagerPath)

                Invoke-WUAndroidSdkManager `
                    -SdkManagerPath $SdkManagerPath `
                    -ArgumentList '--list' `
                    -ErrorAction Stop
            } $script:SdkManagerPath
        } | Should -Not -Throw
    }

    It 'reports native output with a nonzero exit code' -Skip:($env:OS -ne 'Windows_NT') {
        [System.IO.File]::WriteAllLines(
            $script:SdkManagerPath,
            @('@echo off', 'echo sdk failure 1>&2', 'exit /b 7')
        )

        {
            & $script:Module {
                param($SdkManagerPath)

                Invoke-WUAndroidSdkManager `
                    -SdkManagerPath $SdkManagerPath `
                    -ArgumentList '--list'
            } $script:SdkManagerPath
        } | Should -Throw '*exit code 7*sdk failure*'
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
        $null = New-Item -Path $firstVersionPath -ItemType Directory -Force
        $null = New-Item -Path $secondVersionPath -ItemType Directory -Force

        & $script:Module {
            param($BuildToolsPath)

            Set-WUAndroidBuildToolsLatest `
                -BuildToolsPath $BuildToolsPath `
                -Version '35.0.0'
            Set-WUAndroidBuildToolsLatest `
                -BuildToolsPath $BuildToolsPath `
                -Version '36.0.0'
        } $script:BuildToolsPath

        $latestPath = Join-Path -Path $script:BuildToolsPath -ChildPath 'latest'
        $latest = Get-Item -LiteralPath $latestPath -Force
        $latest.Attributes -band [System.IO.FileAttributes]::ReparsePoint |
            Should -Not -Be 0
        & $script:Module {
            param($ReferencePath, $DifferencePath)

            Compare-WUPath -ReferencePath $ReferencePath -DifferencePath $DifferencePath
        } $secondVersionPath ([string]@($latest.Target)[0]) | Should -BeTrue
    }

    It 'preserves an ordinary latest directory' {
        $versionPath = Join-Path -Path $script:BuildToolsPath -ChildPath '36.0.0'
        $latestPath = Join-Path -Path $script:BuildToolsPath -ChildPath 'latest'
        $null = New-Item -Path $versionPath -ItemType Directory -Force
        $null = New-Item -Path $latestPath -ItemType Directory -Force

        {
            & $script:Module {
                param($BuildToolsPath)

                Set-WUAndroidBuildToolsLatest `
                    -BuildToolsPath $BuildToolsPath `
                    -Version '36.0.0'
            } $script:BuildToolsPath
        } | Should -Throw '*not a directory junction*'

        Test-Path -LiteralPath $latestPath -PathType Container | Should -BeTrue
    }
}

Describe 'Install-WUAndroidSdk' {
    BeforeEach {
        $script:SdkPath = Join-Path -Path $TestDrive -ChildPath 'AndroidSdk'
        Remove-Item -LiteralPath $script:SdkPath -Recurse -Force -ErrorAction Ignore

        Mock -CommandName Install-WUAndroidCommandLineTools -ModuleName PSWinUtil -MockWith {
            $sdkManagerDirectory = Join-Path -Path $SdkPath -ChildPath 'cmdline-tools\latest\bin'
            $null = New-Item -Path $sdkManagerDirectory -ItemType Directory -Force
            [System.IO.File]::WriteAllText(
                (Join-Path -Path $sdkManagerDirectory -ChildPath 'sdkmanager.bat'),
                '@echo off'
            )
        }
        Mock -CommandName Invoke-WUAndroidSdkManager -ModuleName PSWinUtil -MockWith {
            if ($ArgumentList -contains '--list') {
                return @(
                    '  build-tools;35.0.1 | 35.0.1 | Android SDK Build-Tools 35.0.1'
                    '  build-tools;36.0.0 | 36.0.0 | Android SDK Build-Tools 36'
                    '  build-tools;37.0.0-rc1 | 37.0.0 rc1 | Android SDK Build-Tools 37 rc1'
                    '  platforms;android-35 | 2 | Android SDK Platform 35'
                    '  platforms;android-36 | 1 | Android SDK Platform 36'
                )
            }

            foreach ($argument in $ArgumentList) {
                if ($argument -eq 'platform-tools') {
                    $directory = Join-Path -Path $script:SdkPath -ChildPath 'platform-tools'
                    $null = New-Item -Path $directory -ItemType Directory -Force
                    [System.IO.File]::WriteAllText((Join-Path -Path $directory -ChildPath 'adb.exe'), '')
                } elseif ($argument -match '^platforms;android-(\d+)$') {
                    $directory = Join-Path -Path $script:SdkPath -ChildPath "platforms\android-$($Matches[1])"
                    $null = New-Item -Path $directory -ItemType Directory -Force
                    [System.IO.File]::WriteAllText((Join-Path -Path $directory -ChildPath 'android.jar'), '')
                } elseif ($argument -match '^build-tools;([0-9]+\.[0-9]+\.[0-9]+)$') {
                    $directory = Join-Path -Path $script:SdkPath -ChildPath "build-tools\$($Matches[1])"
                    $null = New-Item -Path $directory -ItemType Directory -Force
                    [System.IO.File]::WriteAllText((Join-Path -Path $directory -ChildPath 'aapt2.exe'), '')
                } elseif ($argument -eq 'emulator') {
                    $directory = Join-Path -Path $script:SdkPath -ChildPath 'emulator'
                    $null = New-Item -Path $directory -ItemType Directory -Force
                    [System.IO.File]::WriteAllText((Join-Path -Path $directory -ChildPath 'emulator.exe'), '')
                }
            }
        }
        Mock -CommandName Set-WUAndroidBuildToolsLatest -ModuleName PSWinUtil
        Mock -CommandName Set-WUEnvironmentVariable -ModuleName PSWinUtil
        Mock -CommandName Add-WUPathEnvironmentVariable -ModuleName PSWinUtil
    }

    It 'resolves and installs the latest stable package versions' {
        $result = Install-WUAndroidSdk -SdkPath $script:SdkPath

        $result | Should -BeOfType ([System.IO.DirectoryInfo])
        Should -Invoke -CommandName Invoke-WUAndroidSdkManager -ModuleName PSWinUtil -Times 1 -Exactly -ParameterFilter {
            $ArgumentList -contains '--list' -and
            $ArgumentList -contains '--channel=0' -and
            $ArgumentList -contains "--sdk_root=$script:SdkPath"
        }
        Should -Invoke -CommandName Invoke-WUAndroidSdkManager -ModuleName PSWinUtil -Times 1 -Exactly -ParameterFilter {
            $ArgumentList -contains 'platform-tools' -and
            $ArgumentList -contains 'platforms;android-36' -and
            $ArgumentList -contains 'build-tools;36.0.0' -and
            $ArgumentList -contains 'emulator' -and
            $ArgumentList -contains '--channel=0'
        }
        Should -Invoke -CommandName Set-WUAndroidBuildToolsLatest -ModuleName PSWinUtil -Times 1 -Exactly -ParameterFilter {
            $Version -eq '36.0.0'
        }
    }

    It 'maps explicit versions without listing available packages' {
        Install-WUAndroidSdk `
            -SdkPath $script:SdkPath `
            -PlatformVersion 35 `
            -BuildToolsVersion '35.0.1'

        Should -Invoke -CommandName Invoke-WUAndroidSdkManager -ModuleName PSWinUtil -Times 0 -Exactly -ParameterFilter {
            $ArgumentList -contains '--list'
        }
        Should -Invoke -CommandName Invoke-WUAndroidSdkManager -ModuleName PSWinUtil -Times 1 -Exactly -ParameterFilter {
            $ArgumentList -contains 'platforms;android-35' -and
            $ArgumentList -contains 'build-tools;35.0.1'
        }
    }

    It 'does not reinstall components that are already present' {
        & {
            $directories = @(
                (Join-Path -Path $script:SdkPath -ChildPath 'platform-tools')
                (Join-Path -Path $script:SdkPath -ChildPath 'platforms\android-36')
                (Join-Path -Path $script:SdkPath -ChildPath 'build-tools\36.0.0')
                (Join-Path -Path $script:SdkPath -ChildPath 'emulator')
            )
            foreach ($directory in $directories) {
                $null = New-Item -Path $directory -ItemType Directory -Force
            }
            [System.IO.File]::WriteAllText((Join-Path -Path $directories[0] -ChildPath 'adb.exe'), '')
            [System.IO.File]::WriteAllText((Join-Path -Path $directories[1] -ChildPath 'android.jar'), '')
            [System.IO.File]::WriteAllText((Join-Path -Path $directories[2] -ChildPath 'aapt2.exe'), '')
            [System.IO.File]::WriteAllText((Join-Path -Path $directories[3] -ChildPath 'emulator.exe'), '')
        }

        Install-WUAndroidSdk `
            -SdkPath $script:SdkPath `
            -PlatformVersion 36 `
            -BuildToolsVersion '36.0.0'

        Should -Invoke -CommandName Invoke-WUAndroidSdkManager -ModuleName PSWinUtil -Times 0 -Exactly
    }

    It 'installs only the missing SDK package' -TestCases @(
        @{
            MissingPath = 'platform-tools\adb.exe'
            Package = 'platform-tools'
        }
        @{
            MissingPath = 'platforms\android-36\android.jar'
            Package = 'platforms;android-36'
        }
        @{
            MissingPath = 'build-tools\36.0.0\aapt2.exe'
            Package = 'build-tools;36.0.0'
        }
        @{
            MissingPath = 'emulator\emulator.exe'
            Package = 'emulator'
        }
    ) {
        param($MissingPath, $Package)

        $script:ExpectedPackage = $Package
        $requiredPaths = @(
            'platform-tools\adb.exe'
            'platforms\android-36\android.jar'
            'build-tools\36.0.0\aapt2.exe'
            'emulator\emulator.exe'
        )
        foreach ($requiredPath in $requiredPaths) {
            if ($requiredPath -eq $MissingPath) {
                continue
            }
            $fullPath = Join-Path -Path $script:SdkPath -ChildPath $requiredPath
            $null = New-Item -Path (Split-Path -Path $fullPath -Parent) -ItemType Directory -Force
            [System.IO.File]::WriteAllText($fullPath, '')
        }

        Install-WUAndroidSdk `
            -SdkPath $script:SdkPath `
            -PlatformVersion 36 `
            -BuildToolsVersion '36.0.0'

        Should -Invoke -CommandName Invoke-WUAndroidSdkManager -ModuleName PSWinUtil -Times 1 -Exactly -ParameterFilter {
            @($ArgumentList | Where-Object { $_ -notlike '--*' }) -contains $script:ExpectedPackage -and
            @($ArgumentList | Where-Object { $_ -notlike '--*' }).Count -eq 1
        }
    }

    It 'sets ANDROID_HOME and adds persistent and process PATH entries' {
        Install-WUAndroidSdk `
            -SdkPath $script:SdkPath `
            -PlatformVersion 36 `
            -BuildToolsVersion '36.0.0'

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
            $Path -contains '%ANDROID_HOME%\cmdline-tools\latest\bin' -and
            $Path -contains '%ANDROID_HOME%\build-tools\latest'
        }
        Should -Invoke -CommandName Add-WUPathEnvironmentVariable -ModuleName PSWinUtil -Times 1 -Exactly -ParameterFilter {
            $Scope -eq 'Process' -and
            $Path -contains (Join-Path -Path $script:SdkPath -ChildPath 'platform-tools') -and
            $Path -contains (Join-Path -Path $script:SdkPath -ChildPath 'emulator')
        }
    }

    It 'does not start the installation with WhatIf' {
        Install-WUAndroidSdk -SdkPath $script:SdkPath -WhatIf

        Should -Invoke -CommandName Install-WUAndroidCommandLineTools -ModuleName PSWinUtil -Times 0 -Exactly
        Should -Invoke -CommandName Invoke-WUAndroidSdkManager -ModuleName PSWinUtil -Times 0 -Exactly
        Should -Invoke -CommandName Set-WUEnvironmentVariable -ModuleName PSWinUtil -Times 0 -Exactly
        Should -Invoke -CommandName Add-WUPathEnvironmentVariable -ModuleName PSWinUtil -Times 0 -Exactly
    }
}
