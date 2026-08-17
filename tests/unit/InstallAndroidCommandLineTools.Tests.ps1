BeforeAll {
    $repositoryRoot = Split-Path -Path (Split-Path -Path $PSScriptRoot -Parent) -Parent
    $manifestPath = Join-Path -Path $repositoryRoot -ChildPath 'output/PSWinUtil/PSWinUtil.psd1'
    Import-Module -Name $manifestPath -Force -ErrorAction Stop

    Add-Type -AssemblyName 'System.IO.Compression.FileSystem' -ErrorAction Stop
}

Describe 'Install-WUAndroidCommandLineTools' {
    BeforeEach {
        $script:AndroidHome = Join-Path -Path $TestDrive -ChildPath 'AndroidSdk'
        $script:DownloadDirectory = Join-Path -Path $TestDrive -ChildPath 'Downloads'
        $null = New-Item -Path $script:AndroidHome -ItemType Directory -Force
        $null = New-Item -Path $script:DownloadDirectory -ItemType Directory -Force

        Mock -CommandName Get-WUAndroidCommandLineToolsUrl -ModuleName PSWinUtil -MockWith {
            'https://dl.google.com/android/repository/commandlinetools-win-123456_latest.zip'
        }
        Mock -CommandName Invoke-WUDefaultBrowserDownloadInternal -ModuleName PSWinUtil -MockWith {
            $zipSource = Join-Path -Path $TestDrive -ChildPath "ZipSource-$([guid]::NewGuid().ToString('N'))"
            $sdkManagerDirectory = Join-Path -Path $zipSource -ChildPath 'cmdline-tools\bin'
            $null = New-Item -Path $sdkManagerDirectory -ItemType Directory -Force
            [IO.File]::WriteAllText(
                (Join-Path -Path $sdkManagerDirectory -ChildPath 'sdkmanager.bat'),
                '@echo off'
            )
            $zipPath = Join-Path -Path $DownloadDirectory -ChildPath $FileName
            [IO.Compression.ZipFile]::CreateFromDirectory($zipSource, $zipPath)
            Remove-Item -LiteralPath $zipSource -Recurse -Force
            $zipPath
        }
    }

    It 'requires AndroidHome' {
        {
            Install-WUAndroidCommandLineTools -AndroidHome '' -DownloadDirectory $script:DownloadDirectory
        } | Should -Throw '*AndroidHome is required*'
    }

    It 'does not expose a license switch' {
        (Get-Command -Name Install-WUAndroidCommandLineTools).Parameters.Keys |
            Should -Not -Contain 'AcceptLicense'
    }

    It 'requires an existing AndroidHome directory' {
        $missingPath = Join-Path -Path $TestDrive -ChildPath 'MissingSdk'

        {
            Install-WUAndroidCommandLineTools -AndroidHome $missingPath -DownloadDirectory $script:DownloadDirectory
        } | Should -Throw '*does not exist*'
    }

    It 'does not start the operation with WhatIf' {
        Install-WUAndroidCommandLineTools -AndroidHome $script:AndroidHome -DownloadDirectory $script:DownloadDirectory -WhatIf

        Should -Invoke -CommandName Get-WUAndroidCommandLineToolsUrl -ModuleName PSWinUtil -Times 0 -Exactly
        Should -Invoke -CommandName Invoke-WUDefaultBrowserDownloadInternal -ModuleName PSWinUtil -Times 0 -Exactly
    }

    It 'installs the validated package and returns the directory' {
        $result = Install-WUAndroidCommandLineTools -AndroidHome $script:AndroidHome -DownloadDirectory $script:DownloadDirectory -PassThru
        $latestPath = Join-Path -Path $script:AndroidHome -ChildPath 'cmdline-tools\latest'

        $result | Should -BeOfType ([System.IO.DirectoryInfo])
        $result.FullName | Should -Be ([IO.Path]::GetFullPath($latestPath))
        Test-Path -LiteralPath (Join-Path -Path $latestPath -ChildPath 'bin\sdkmanager.bat') -PathType Leaf |
            Should -BeTrue
        Get-ChildItem -LiteralPath $script:DownloadDirectory -File | Should -HaveCount 0
        Should -Invoke -CommandName Get-WUAndroidCommandLineToolsUrl -ModuleName PSWinUtil -Times 1 -Exactly
        Should -Invoke -CommandName Invoke-WUDefaultBrowserDownloadInternal -ModuleName PSWinUtil -Times 1 -Exactly -ParameterFilter {
            $Force -and $TimeoutSeconds -eq 300
        }
    }

    It 'replaces an existing latest directory' {
        $latestPath = Join-Path -Path $script:AndroidHome -ChildPath 'cmdline-tools\latest'
        $null = New-Item -Path $latestPath -ItemType Directory -Force
        [IO.File]::WriteAllText((Join-Path -Path $latestPath -ChildPath 'old.txt'), 'old')

        Install-WUAndroidCommandLineTools -AndroidHome $script:AndroidHome -DownloadDirectory $script:DownloadDirectory

        Test-Path -LiteralPath (Join-Path -Path $latestPath -ChildPath 'old.txt') | Should -BeFalse
        Test-Path -LiteralPath (Join-Path -Path $latestPath -ChildPath 'bin\sdkmanager.bat') | Should -BeTrue
        Get-ChildItem -LiteralPath (Split-Path -Path $latestPath -Parent) -Directory -Filter '.latest-backup-*' |
            Should -HaveCount 0
    }

    It 'keeps an existing latest directory when package validation fails' {
        $latestPath = Join-Path -Path $script:AndroidHome -ChildPath 'cmdline-tools\latest'
        $null = New-Item -Path $latestPath -ItemType Directory -Force
        $oldPath = Join-Path -Path $latestPath -ChildPath 'old.txt'
        [IO.File]::WriteAllText($oldPath, 'old')
        Mock -CommandName Invoke-WUDefaultBrowserDownloadInternal -ModuleName PSWinUtil -MockWith {
            $zipSource = Join-Path -Path $TestDrive -ChildPath 'InvalidZipSource'
            $null = New-Item -Path $zipSource -ItemType Directory -Force
            [IO.File]::WriteAllText((Join-Path -Path $zipSource -ChildPath 'unexpected.txt'), 'bad')
            $zipPath = Join-Path -Path $DownloadDirectory -ChildPath $FileName
            [IO.Compression.ZipFile]::CreateFromDirectory($zipSource, $zipPath)
            Remove-Item -LiteralPath $zipSource -Recurse -Force
            $zipPath
        }

        {
            Install-WUAndroidCommandLineTools -AndroidHome $script:AndroidHome -DownloadDirectory $script:DownloadDirectory
        } | Should -Throw '*expected cmdline-tools*'

        Test-Path -LiteralPath $oldPath -PathType Leaf | Should -BeTrue
        Get-ChildItem -LiteralPath $script:DownloadDirectory -File | Should -HaveCount 0
    }

    It 'removes the downloaded archive when extraction fails' {
        Mock -CommandName Invoke-WUDefaultBrowserDownloadInternal -ModuleName PSWinUtil -MockWith {
            $zipPath = Join-Path -Path $DownloadDirectory -ChildPath $FileName
            [IO.File]::WriteAllText($zipPath, 'not a zip file')
            $zipPath
        }

        {
            Install-WUAndroidCommandLineTools -AndroidHome $script:AndroidHome -DownloadDirectory $script:DownloadDirectory
        } | Should -Throw

        Get-ChildItem -LiteralPath $script:DownloadDirectory -File | Should -HaveCount 0
    }
}
