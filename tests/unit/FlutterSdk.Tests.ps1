BeforeAll {
    $repositoryRoot = Split-Path -Path (Split-Path -Path $PSScriptRoot -Parent) -Parent
    $manifestPath = Join-Path -Path $repositoryRoot -ChildPath 'output/PSWinUtil/PSWinUtil.psd1'
    Import-Module -Name $manifestPath -Force -ErrorAction Stop

    Add-Type -AssemblyName 'System.IO.Compression.FileSystem' -ErrorAction Stop
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

    It 'reports incomplete release metadata' {
        $script:ReleaseIndex = $script:ReleaseIndex.Replace(
            '1111111111111111111111111111111111111111111111111111111111111111',
            ''
        )

        { Get-WUFlutterSdkUrl } | Should -Throw '*incomplete archive metadata*'
    }
}

Describe 'Install-WUFlutterSdk' {
    BeforeEach {
        $script:DestinationPath = Join-Path -Path $TestDrive -ChildPath 'develop'
        $script:PackagePath = Join-Path -Path $TestDrive -ChildPath 'flutter-package.zip'
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
        $script:PackageHash = (Get-FileHash -LiteralPath $script:PackagePath -Algorithm SHA256).Hash

        Mock -CommandName Get-WUFlutterSdkRelease -ModuleName PSWinUtil -MockWith {
            [pscustomobject]@{
                Version = '3.47.1'
                Channel = 'stable'
                Architecture = 'x64'
                Uri = [uri]'https://storage.example.test/flutter_windows_3.47.1-stable.zip'
                Sha256 = $script:PackageHash
            }
        }
        Mock -CommandName Invoke-WUHttpFileDownload -ModuleName PSWinUtil -MockWith {
            Copy-Item -LiteralPath $script:PackagePath -Destination $Path
            $Path
        }
        Mock -CommandName Add-WUPathEnvironmentVariable -ModuleName PSWinUtil -MockWith {}
    }

    It 'does not start the operation with WhatIf' {
        Install-WUFlutterSdk -DestinationPath $script:DestinationPath -WhatIf

        Test-Path -LiteralPath $script:DestinationPath | Should -BeFalse
        Should -Invoke -CommandName Get-WUFlutterSdkRelease -ModuleName PSWinUtil -Times 0 -Exactly
        Should -Invoke -CommandName Invoke-WUHttpFileDownload -ModuleName PSWinUtil -Times 0 -Exactly
        Should -Invoke -CommandName Add-WUPathEnvironmentVariable -ModuleName PSWinUtil -Times 0 -Exactly
    }

    It 'installs a verified package and configures both PATH scopes' {
        $result = Install-WUFlutterSdk `
            -Version '3.47.1' `
            -DestinationPath $script:DestinationPath `
            -TimeoutSeconds 120
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
    }

    It 'replaces an existing installation after validating the new package' {
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

    It 'keeps an existing installation when the package hash is invalid' {
        $existingFlutterPath = Join-Path -Path $script:DestinationPath -ChildPath 'flutter'
        $null = New-Item -Path $existingFlutterPath -ItemType Directory -Force
        $oldFilePath = Join-Path -Path $existingFlutterPath -ChildPath 'old.txt'
        [IO.File]::WriteAllText($oldFilePath, 'old')
        $script:PackageHash = '0000000000000000000000000000000000000000000000000000000000000000'

        {
            Install-WUFlutterSdk -DestinationPath $script:DestinationPath
        } | Should -Throw '*official SHA-256 hash*'

        Test-Path -LiteralPath $oldFilePath -PathType Leaf | Should -BeTrue
        Get-ChildItem -LiteralPath $script:DestinationPath -Directory -Filter '.flutter-install-*' |
            Should -HaveCount 0
    }

    It 'keeps an existing installation when package validation fails' {
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
        $script:PackageHash = (Get-FileHash -LiteralPath $script:PackagePath -Algorithm SHA256).Hash

        {
            Install-WUFlutterSdk -DestinationPath $script:DestinationPath
        } | Should -Throw '*expected flutter*'

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
        $script:PackageHash = (Get-FileHash -LiteralPath $script:PackagePath -Algorithm SHA256).Hash
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
}
