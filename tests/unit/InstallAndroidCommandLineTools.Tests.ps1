BeforeAll {
    . (Join-Path -Path $PSScriptRoot -ChildPath '../UnitTestBootstrap.ps1')

    Add-Type -AssemblyName 'System.IO.Compression.FileSystem' -ErrorAction Stop
}

Describe 'Install-WUAndroidCommandLineTools' {
    BeforeEach {
        $script:SdkPath = Join-Path -Path $TestDrive -ChildPath 'AndroidSdk'
        Remove-Item -LiteralPath $script:SdkPath -Recurse -Force -ErrorAction Ignore

        $script:Package = [pscustomobject]@{
            Uri = [uri]'https://dl.google.com/android/repository/commandlinetools-win-123456_latest.zip'
            FileName = 'commandlinetools-win-123456_latest.zip'
            Sha256 = $null
        }
        Mock -CommandName Get-WUAndroidCommandLineToolsPackage -ModuleName PSWinUtil -MockWith {
            $script:Package
        }
        Mock -CommandName Invoke-WUHttpFileDownload -ModuleName PSWinUtil -MockWith {
            $zipSource = Join-Path -Path $TestDrive -ChildPath "ZipSource-$([guid]::NewGuid().ToString('N'))"
            $sdkManagerDirectory = Join-Path -Path $zipSource -ChildPath 'cmdline-tools\bin'
            $null = New-Item -Path $sdkManagerDirectory -ItemType Directory -Force
            [System.IO.File]::WriteAllText(
                (Join-Path -Path $sdkManagerDirectory -ChildPath 'sdkmanager.bat'),
                '@echo off'
            )
            [System.IO.Compression.ZipFile]::CreateFromDirectory($zipSource, $Path)
            Remove-Item -LiteralPath $zipSource -Recurse -Force
            $script:Package.Sha256 = (Get-FileHash -LiteralPath $Path -Algorithm SHA256).Hash
            $Path
        }
    }

    It 'exposes only SdkPath as a command parameter' {
        $command = Get-Command -Name Install-WUAndroidCommandLineTools
        $command.Parameters.Keys | Should -Contain 'SdkPath'
        $command.Parameters.Keys | Should -Not -Contain 'AndroidHome'
        $command.Parameters.Keys | Should -Not -Contain 'DownloadDirectory'
        $command.Parameters.Keys | Should -Not -Contain 'TimeoutSeconds'
        $command.Parameters.Keys | Should -Not -Contain 'PassThru'
    }

    It 'requires SdkPath when LOCALAPPDATA is unavailable' {
        {
            Install-WUAndroidCommandLineTools -SdkPath ''
        } | Should -Throw '*SdkPath is required*'
    }

    It 'creates the SDK directory and installs the validated package' {
        Install-WUAndroidCommandLineTools -SdkPath $script:SdkPath
        $sdkManagerPath = Join-Path `
            -Path $script:SdkPath `
            -ChildPath 'cmdline-tools\latest\bin\sdkmanager.bat'

        Test-Path -LiteralPath $sdkManagerPath -PathType Leaf | Should -BeTrue
        Should -Invoke -CommandName Get-WUAndroidCommandLineToolsPackage -ModuleName PSWinUtil -Times 1 -Exactly
        Should -Invoke -CommandName Invoke-WUHttpFileDownload -ModuleName PSWinUtil -Times 1 -Exactly -ParameterFilter {
            $Uri.AbsoluteUri -eq 'https://dl.google.com/android/repository/commandlinetools-win-123456_latest.zip'
        }
    }

    It 'does not download when sdkmanager is already installed' {
        $sdkManagerDirectory = Join-Path `
            -Path $script:SdkPath `
            -ChildPath 'cmdline-tools\latest\bin'
        $null = New-Item -Path $sdkManagerDirectory -ItemType Directory -Force
        [System.IO.File]::WriteAllText(
            (Join-Path -Path $sdkManagerDirectory -ChildPath 'sdkmanager.bat'),
            '@echo off'
        )

        Install-WUAndroidCommandLineTools -SdkPath $script:SdkPath

        Should -Invoke -CommandName Get-WUAndroidCommandLineToolsPackage -ModuleName PSWinUtil -Times 0 -Exactly
        Should -Invoke -CommandName Invoke-WUHttpFileDownload -ModuleName PSWinUtil -Times 0 -Exactly
    }

    It 'does not start the installation with WhatIf' {
        Install-WUAndroidCommandLineTools -SdkPath $script:SdkPath -WhatIf

        Test-Path -LiteralPath $script:SdkPath | Should -BeFalse
        Should -Invoke -CommandName Get-WUAndroidCommandLineToolsPackage -ModuleName PSWinUtil -Times 0 -Exactly
        Should -Invoke -CommandName Invoke-WUHttpFileDownload -ModuleName PSWinUtil -Times 0 -Exactly
    }

    It 'keeps an existing latest directory when package validation fails' {
        $latestPath = Join-Path -Path $script:SdkPath -ChildPath 'cmdline-tools\latest'
        $null = New-Item -Path $latestPath -ItemType Directory -Force
        $oldPath = Join-Path -Path $latestPath -ChildPath 'old.txt'
        [System.IO.File]::WriteAllText($oldPath, 'old')
        Mock -CommandName Invoke-WUHttpFileDownload -ModuleName PSWinUtil -MockWith {
            $zipSource = Join-Path -Path $TestDrive -ChildPath 'InvalidZipSource'
            $null = New-Item -Path $zipSource -ItemType Directory -Force
            [System.IO.File]::WriteAllText((Join-Path -Path $zipSource -ChildPath 'unexpected.txt'), 'bad')
            [System.IO.Compression.ZipFile]::CreateFromDirectory($zipSource, $Path)
            Remove-Item -LiteralPath $zipSource -Recurse -Force
            $script:Package.Sha256 = (Get-FileHash -LiteralPath $Path -Algorithm SHA256).Hash
            $Path
        }

        {
            Install-WUAndroidCommandLineTools -SdkPath $script:SdkPath
        } | Should -Throw '*expected cmdline-tools*'

        Test-Path -LiteralPath $oldPath -PathType Leaf | Should -BeTrue
    }

    It 'rejects a package with an unexpected checksum' {
        $script:Package.Sha256 = '0000000000000000000000000000000000000000000000000000000000000000'
        Mock -CommandName Invoke-WUHttpFileDownload -ModuleName PSWinUtil -MockWith {
            [System.IO.File]::WriteAllText($Path, 'unexpected content')
            $Path
        }

        {
            Install-WUAndroidCommandLineTools -SdkPath $script:SdkPath
        } | Should -Throw '*checksum is invalid*'

        Test-Path -LiteralPath $script:SdkPath -PathType Container | Should -BeFalse
    }
}
