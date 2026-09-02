BeforeAll {
    . (Join-Path -Path $PSScriptRoot -ChildPath '../UnitTestBootstrap.ps1')

    $script:Module = Get-Module -Name 'PSWinUtil' -ErrorAction Stop

    Add-Type -AssemblyName 'System.IO.Compression.FileSystem' -ErrorAction Stop

    $powerShellExecutableName = 'pwsh'
    if ($PSVersionTable.PSEdition -eq 'Desktop') {
        $powerShellExecutableName = 'powershell.exe'
    }
    $script:PowerShellExecutable = Join-Path -Path $PSHOME -ChildPath $powerShellExecutableName
}

Describe 'Get-WUFlutterSdkUrl' {
    BeforeEach {
        $script:ReleaseIndex = @'
{
  "base_url": "https://storage.example.test/flutter/releases",
  "current_release": {
    "stable": "stable-current",
    "beta": "beta-current"
  },
  "releases": [
    {
      "hash": "stable-current",
      "channel": "stable",
      "version": "3.47.1",
      "dart_sdk_arch": "x64",
      "archive": "stable/windows/flutter_windows_3.47.1-stable.zip",
      "sha256": "1111111111111111111111111111111111111111111111111111111111111111"
    },
    {
      "hash": "beta-current",
      "channel": "beta",
      "version": "3.47.1",
      "dart_sdk_arch": "x64",
      "archive": "beta/windows/flutter_windows_3.47.1-beta.zip",
      "sha256": "2222222222222222222222222222222222222222222222222222222222222222"
    },
    {
      "hash": "beta-arm64",
      "channel": "beta",
      "version": "3.48.0-0.1.pre",
      "arch": "arm64",
      "archive": "beta/windows/flutter_windows_3.48.0-0.1.pre-beta-arm64.zip",
      "sha256": "3333333333333333333333333333333333333333333333333333333333333333"
    },
    {
      "hash": "legacy-stable",
      "channel": "stable",
      "version": "2.0.0",
      "archive": "stable/windows/flutter_windows_2.0.0-stable.zip",
      "sha256": "4444444444444444444444444444444444444444444444444444444444444444"
    }
  ]
}
'@
        Mock -CommandName Invoke-WebRequest -ModuleName PSWinUtil -MockWith {
            [pscustomobject]@{ Content = $script:ReleaseIndex }
        }
    }

    It 'returns the current release for the selected channel and architecture' {
        Get-WUFlutterSdkUrl -Channel 'stable' -Architecture 'x64' |
            Should -Be 'https://storage.example.test/flutter/releases/stable/windows/flutter_windows_3.47.1-stable.zip'
    }

    It 'applies the channel when selecting a specific version' {
        Get-WUFlutterSdkUrl -Version '3.47.1' -Channel 'beta' -Architecture 'x64' |
            Should -Be 'https://storage.example.test/flutter/releases/beta/windows/flutter_windows_3.47.1-beta.zip'
    }

    It 'uses the newest matching architecture when the current hash has another architecture' {
        Get-WUFlutterSdkUrl -Channel 'beta' -Architecture 'arm64' |
            Should -Be 'https://storage.example.test/flutter/releases/beta/windows/flutter_windows_3.48.0-0.1.pre-beta-arm64.zip'
    }

    It 'treats a legacy release without architecture metadata as x64' {
        Get-WUFlutterSdkUrl -Version '2.0.0' -Architecture 'x64' |
            Should -Be 'https://storage.example.test/flutter/releases/stable/windows/flutter_windows_2.0.0-stable.zip'
    }

    It 'does not return another architecture when the requested architecture is unavailable' {
        {
            Get-WUFlutterSdkUrl -Version '3.47.1' -Architecture 'arm64'
        } | Should -Throw "*architecture 'arm64'*"
    }

    It 'accepts only channels published in the Windows release archive' {
        $validateSet = @(
            (Get-Command -Name Get-WUFlutterSdkUrl).Parameters['Channel'].Attributes |
                Where-Object { $_ -is [Management.Automation.ValidateSetAttribute] }
        )

        $validateSet | Should -HaveCount 1
        $validateSet[0].ValidValues | Should -Be @('stable', 'beta')
    }

    It 'reports an HTTP request failure' {
        Mock -CommandName Invoke-WebRequest -ModuleName PSWinUtil -MockWith {
            throw 'network failure'
        }

        { Get-WUFlutterSdkUrl } | Should -Throw '*network failure*'
    }

    It 'reports a missing archive path' {
        $script:ReleaseIndex = $script:ReleaseIndex.Replace(
            'stable/windows/flutter_windows_3.47.1-stable.zip',
            ''
        )

        { Get-WUFlutterSdkUrl } | Should -Throw '*archive path*'
    }
}

Describe 'Invoke-WUFlutterSdkCommand' {
    It 'displays command output and accepts a zero exit code' {
        $informationOutput = @(
            & $script:Module {
                param($Executable)

                Invoke-WUFlutterSdkCommand -Command $Executable -ArgumentList '-NoProfile', '-Command', 'Write-Output command-output; exit 0'
            } $script:PowerShellExecutable 6>&1
        )

        @($informationOutput | ForEach-Object { [string]$_ }) |
            Should -Contain 'command-output'
    }

    It 'reports a nonzero exit code' {
        {
            & $script:Module {
                param($Executable)

                Invoke-WUFlutterSdkCommand -Command $Executable -ArgumentList '-NoProfile', '-Command', 'exit 7'
            } $script:PowerShellExecutable
        } | Should -Throw '*exit code 7*'
    }

    It 'can display a report without using its exit code as a success condition' {
        {
            & $script:Module {
                param($Executable)

                Invoke-WUFlutterSdkCommand -Command $Executable -ArgumentList '-NoProfile', '-Command', 'Write-Output report-output; exit 9' -IgnoreExitCode
            } $script:PowerShellExecutable
        } | Should -Not -Throw
    }
}

Describe 'Install-WUFlutterSdk' {
    BeforeEach {
        $script:DestinationPath = Join-Path -Path $TestDrive -ChildPath 'develop'
        $script:PackagePath = Join-Path -Path $TestDrive -ChildPath 'flutter-package.zip'
        $script:OperationOrder = @()
        $packageSource = Join-Path -Path $TestDrive -ChildPath 'FlutterPackageSource'
        Remove-Item -LiteralPath $script:DestinationPath -Recurse -Force -ErrorAction Ignore
        Remove-Item -LiteralPath $script:PackagePath -Force -ErrorAction Ignore
        Remove-Item -LiteralPath $packageSource -Recurse -Force -ErrorAction Ignore
        $flutterBin = Join-Path -Path $packageSource -ChildPath 'flutter\bin'
        $null = New-Item -Path $flutterBin -ItemType Directory -Force
        [IO.File]::WriteAllText(
            (Join-Path -Path $flutterBin -ChildPath 'flutter.bat'),
            '@echo off'
        )
        [IO.Compression.ZipFile]::CreateFromDirectory($packageSource, $script:PackagePath)

        Mock -CommandName Get-WUFlutterSdkRelease -ModuleName PSWinUtil -MockWith {
            $script:OperationOrder += 'release'
            [pscustomobject]@{
                Version = '3.47.1'
                Channel = 'stable'
                Architecture = 'x64'
                Uri = [uri]'https://storage.example.test/flutter_windows_3.47.1-stable.zip'
            }
        }
        Mock -CommandName Invoke-WUHttpFileDownload -ModuleName PSWinUtil -MockWith {
            $script:OperationOrder += 'download'
            if (-not (Test-Path -LiteralPath $script:DestinationPath -PathType Container)) {
                throw 'The destination directory must exist before the download starts.'
            }
            Copy-Item -LiteralPath $script:PackagePath -Destination $Path
            $Path
        }
        Mock -CommandName Add-WUPathEnvironmentVariable -ModuleName PSWinUtil -MockWith {
            $script:OperationOrder += "path-$Scope"
        }
        Mock -CommandName Invoke-WUFlutterSdkCommand -ModuleName PSWinUtil -MockWith {
            $script:OperationOrder += "$Command $($ArgumentList -join ' ')"
        }
    }

    It 'does not start the operation with WhatIf' {
        Install-WUFlutterSdk -DestinationPath $script:DestinationPath -WhatIf

        Test-Path -LiteralPath $script:DestinationPath | Should -BeFalse
        Should -Invoke -CommandName Get-WUFlutterSdkRelease -ModuleName PSWinUtil -Times 0 -Exactly
        Should -Invoke -CommandName Invoke-WUHttpFileDownload -ModuleName PSWinUtil -Times 0 -Exactly
        Should -Invoke -CommandName Add-WUPathEnvironmentVariable -ModuleName PSWinUtil -Times 0 -Exactly
        Should -Invoke -CommandName Invoke-WUFlutterSdkCommand -ModuleName PSWinUtil -Times 0 -Exactly
    }

    It 'uses USERPROFILE as the default parent and validates both destination paths' {
        $originalUserProfile = $env:USERPROFILE
        $env:USERPROFILE = $TestDrive
        Mock -CommandName Assert-WUPathProperty -ModuleName PSWinUtil -MockWith {}
        try {
            Install-WUFlutterSdk -WhatIf
        } finally {
            $env:USERPROFILE = $originalUserProfile
        }
        $expectedFlutterPath = Join-Path -Path $TestDrive -ChildPath 'flutter'

        Should -Invoke -CommandName Assert-WUPathProperty -ModuleName PSWinUtil -Times 1 -Exactly -ParameterFilter {
            $LiteralPath -eq $TestDrive -and $Container -and $AllowNonExisting
        }
        Should -Invoke -CommandName Assert-WUPathProperty -ModuleName PSWinUtil -Times 1 -Exactly -ParameterFilter {
            $LiteralPath -eq $expectedFlutterPath -and $Container -and $AllowNonExisting
        }
    }

    It 'rejects an existing destination path that is not a directory' {
        [IO.File]::WriteAllText($script:DestinationPath, 'file')

        {
            Install-WUFlutterSdk -DestinationPath $script:DestinationPath
        } | Should -Throw '*required properties*'

        Should -Invoke -CommandName Get-WUFlutterSdkRelease -ModuleName PSWinUtil -Times 0 -Exactly
    }

    It 'rejects an existing Flutter path that is not a directory' {
        $null = New-Item -Path $script:DestinationPath -ItemType Directory
        [IO.File]::WriteAllText(
            (Join-Path -Path $script:DestinationPath -ChildPath 'flutter'),
            'file'
        )

        {
            Install-WUFlutterSdk -DestinationPath $script:DestinationPath
        } | Should -Throw '*required properties*'

        Should -Invoke -CommandName Get-WUFlutterSdkRelease -ModuleName PSWinUtil -Times 0 -Exactly
    }

    It 'installs the package, configures both PATH scopes, and runs the SDK commands' {
        $result = Install-WUFlutterSdk -Version '3.47.1' -DestinationPath $script:DestinationPath -TimeoutSeconds 120
        $flutterPath = Join-Path -Path $script:DestinationPath -ChildPath 'flutter'
        $flutterBinPath = Join-Path -Path $flutterPath -ChildPath 'bin'

        $result | Should -BeOfType ([System.IO.DirectoryInfo])
        $result.FullName | Should -Be ([IO.Path]::GetFullPath($flutterPath))
        Test-Path -LiteralPath (Join-Path -Path $flutterBinPath -ChildPath 'flutter.bat') -PathType Leaf |
            Should -BeTrue
        Should -Invoke -CommandName Get-WUFlutterSdkRelease -ModuleName PSWinUtil -Times 1 -Exactly -ParameterFilter {
            $Version -eq '3.47.1' -and
            $Channel -eq 'stable' -and
            $Architecture -eq 'x64'
        }
        Should -Invoke -CommandName Invoke-WUHttpFileDownload -ModuleName PSWinUtil -Times 1 -Exactly -ParameterFilter {
            $Uri.AbsoluteUri -eq 'https://storage.example.test/flutter_windows_3.47.1-stable.zip' -and
            $TimeoutSeconds -eq 120
        }
        Should -Invoke -CommandName Add-WUPathEnvironmentVariable -ModuleName PSWinUtil -Times 1 -Exactly -ParameterFilter {
            $Path -eq $flutterBinPath -and $Scope -eq 'User' -and $Prepend
        }
        Should -Invoke -CommandName Add-WUPathEnvironmentVariable -ModuleName PSWinUtil -Times 1 -Exactly -ParameterFilter {
            $Path -eq $flutterBinPath -and $Scope -eq 'Process' -and $Prepend
        }
        Should -Invoke -CommandName Invoke-WUFlutterSdkCommand -ModuleName PSWinUtil -Times 1 -Exactly -ParameterFilter {
            $Command -eq 'flutter' -and
            $ArgumentList.Count -eq 1 -and
            $ArgumentList[0] -eq '--version' -and
            -not $IgnoreExitCode
        }
        Should -Invoke -CommandName Invoke-WUFlutterSdkCommand -ModuleName PSWinUtil -Times 1 -Exactly -ParameterFilter {
            $Command -eq 'dart' -and
            $ArgumentList.Count -eq 1 -and
            $ArgumentList[0] -eq '--version' -and
            -not $IgnoreExitCode
        }
        Should -Invoke -CommandName Invoke-WUFlutterSdkCommand -ModuleName PSWinUtil -Times 1 -Exactly -ParameterFilter {
            $Command -eq 'flutter' -and
            $ArgumentList.Count -eq 1 -and
            $ArgumentList[0] -eq 'doctor' -and
            $IgnoreExitCode
        }
        $script:OperationOrder | Should -Be @(
            'release'
            'download'
            'path-User'
            'path-Process'
            'flutter --version'
            'dart --version'
            'flutter doctor'
        )
    }

    It 'replaces an existing installation after the SDK commands succeed' {
        $existingFlutterPath = Join-Path -Path $script:DestinationPath -ChildPath 'flutter'
        $null = New-Item -Path $existingFlutterPath -ItemType Directory -Force
        [IO.File]::WriteAllText(
            (Join-Path -Path $existingFlutterPath -ChildPath 'old.txt'),
            'old'
        )

        Install-WUFlutterSdk -DestinationPath $script:DestinationPath

        Test-Path -LiteralPath (Join-Path -Path $existingFlutterPath -ChildPath 'old.txt') |
            Should -BeFalse
        Test-Path -LiteralPath (Join-Path -Path $existingFlutterPath -ChildPath 'bin\flutter.bat') |
            Should -BeTrue
        Get-ChildItem -LiteralPath $script:DestinationPath -Directory -Filter '.flutter-backup-*' |
            Should -HaveCount 0
    }

    It 'keeps an existing installation when the extracted SDK cannot be placed' {
        $existingFlutterPath = Join-Path -Path $script:DestinationPath -ChildPath 'flutter'
        $null = New-Item -Path $existingFlutterPath -ItemType Directory -Force
        $oldFilePath = Join-Path -Path $existingFlutterPath -ChildPath 'old.txt'
        [IO.File]::WriteAllText($oldFilePath, 'old')
        Remove-Item -LiteralPath $script:PackagePath -Force
        $invalidSource = Join-Path -Path $TestDrive -ChildPath 'InvalidPackageSource'
        $null = New-Item -Path $invalidSource -ItemType Directory
        [IO.File]::WriteAllText(
            (Join-Path -Path $invalidSource -ChildPath 'unexpected.txt'),
            'invalid'
        )
        [IO.Compression.ZipFile]::CreateFromDirectory($invalidSource, $script:PackagePath)

        {
            Install-WUFlutterSdk -DestinationPath $script:DestinationPath
        } | Should -Throw

        Test-Path -LiteralPath $oldFilePath -PathType Leaf | Should -BeTrue
    }

    It 'rejects archive entries outside the staging directory' {
        Remove-Item -LiteralPath $script:PackagePath -Force
        $archive = [IO.Compression.ZipFile]::Open(
            $script:PackagePath,
            [IO.Compression.ZipArchiveMode]::Create
        )
        try {
            $entry = $archive.CreateEntry('../escaped.txt')
            $writer = [IO.StreamWriter]::new($entry.Open())
            try {
                $writer.Write('unsafe')
            } finally {
                $writer.Dispose()
            }
        } finally {
            $archive.Dispose()
        }
        $escapedPath = Join-Path -Path $script:DestinationPath -ChildPath 'escaped.txt'

        {
            Install-WUFlutterSdk -DestinationPath $script:DestinationPath
        } | Should -Throw '*unsafe path*'

        Test-Path -LiteralPath $escapedPath | Should -BeFalse
    }

    It 'restores an existing installation when PATH configuration fails' {
        $existingFlutterPath = Join-Path -Path $script:DestinationPath -ChildPath 'flutter'
        $null = New-Item -Path $existingFlutterPath -ItemType Directory -Force
        $oldFilePath = Join-Path -Path $existingFlutterPath -ChildPath 'old.txt'
        [IO.File]::WriteAllText($oldFilePath, 'old')
        Mock -CommandName Add-WUPathEnvironmentVariable -ModuleName PSWinUtil -MockWith {
            if ($Scope -eq 'Process') {
                throw 'PATH update failure'
            }
        }

        {
            Install-WUFlutterSdk -DestinationPath $script:DestinationPath
        } | Should -Throw '*PATH update failure*'

        Test-Path -LiteralPath $oldFilePath -PathType Leaf | Should -BeTrue
        Test-Path -LiteralPath (Join-Path -Path $existingFlutterPath -ChildPath 'bin\flutter.bat') |
            Should -BeFalse
    }

    It 'restores an existing installation when flutter version fails' {
        $existingFlutterPath = Join-Path -Path $script:DestinationPath -ChildPath 'flutter'
        $null = New-Item -Path $existingFlutterPath -ItemType Directory -Force
        $oldFilePath = Join-Path -Path $existingFlutterPath -ChildPath 'old.txt'
        [IO.File]::WriteAllText($oldFilePath, 'old')
        Mock -CommandName Invoke-WUFlutterSdkCommand -ModuleName PSWinUtil -MockWith {
            if ($Command -eq 'flutter' -and $ArgumentList[0] -eq '--version') {
                throw 'flutter version failure'
            }
        }

        {
            Install-WUFlutterSdk -DestinationPath $script:DestinationPath
        } | Should -Throw '*flutter version failure*'

        Test-Path -LiteralPath $oldFilePath -PathType Leaf | Should -BeTrue
        Should -Invoke -CommandName Invoke-WUFlutterSdkCommand -ModuleName PSWinUtil -Times 1 -Exactly
    }

    It 'restores an existing installation when dart version fails' {
        $existingFlutterPath = Join-Path -Path $script:DestinationPath -ChildPath 'flutter'
        $null = New-Item -Path $existingFlutterPath -ItemType Directory -Force
        $oldFilePath = Join-Path -Path $existingFlutterPath -ChildPath 'old.txt'
        [IO.File]::WriteAllText($oldFilePath, 'old')
        Mock -CommandName Invoke-WUFlutterSdkCommand -ModuleName PSWinUtil -MockWith {
            if ($Command -eq 'dart' -and $ArgumentList[0] -eq '--version') {
                throw 'dart version failure'
            }
        }

        {
            Install-WUFlutterSdk -DestinationPath $script:DestinationPath
        } | Should -Throw '*dart version failure*'

        Test-Path -LiteralPath $oldFilePath -PathType Leaf | Should -BeTrue
        Should -Invoke -CommandName Invoke-WUFlutterSdkCommand -ModuleName PSWinUtil -Times 2 -Exactly
    }
}
