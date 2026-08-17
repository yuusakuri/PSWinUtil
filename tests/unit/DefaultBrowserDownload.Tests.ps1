BeforeAll {
    $repositoryRoot = Split-Path -Path (Split-Path -Path $PSScriptRoot -Parent) -Parent
    $manifestPath = Join-Path -Path $repositoryRoot -ChildPath 'output/PSWinUtil/PSWinUtil.psd1'
    Import-Module -Name $manifestPath -Force -ErrorAction Stop
}

Describe 'Invoke-WUDefaultBrowserDownload' {
    BeforeEach {
        Get-ChildItem -LiteralPath $TestDrive -File | Remove-Item -Force
        Mock -CommandName Invoke-WUDefaultBrowserDownloadInternal -ModuleName PSWinUtil -MockWith {
            Join-Path -Path $DownloadDirectory -ChildPath $FileName
        }
    }

    It 'gets the file name from Uri' {
        $result = Invoke-WUDefaultBrowserDownload -Uri 'https://example.com/files/package%20one.zip' -DownloadDirectory $TestDrive

        $result | Should -Be (Join-Path -Path $TestDrive -ChildPath 'package one.zip')
        Should -Invoke -CommandName Invoke-WUDefaultBrowserDownloadInternal -ModuleName PSWinUtil -Times 1 -Exactly -ParameterFilter {
            $FileName -eq 'package one.zip'
        }
    }

    It 'requires FileName when Uri has no file segment' {
        { Invoke-WUDefaultBrowserDownload -Uri 'https://example.com/' -DownloadDirectory $TestDrive } |
            Should -Throw '*could not be determined*'
    }

    It 'rejects a FileName that is not a leaf name' {
        { Invoke-WUDefaultBrowserDownload -Uri 'https://example.com/file.zip' -FileName '../file.zip' -DownloadDirectory $TestDrive } |
            Should -Throw '*valid leaf*'
    }

    It 'requires an existing download directory' {
        $missingDirectory = Join-Path -Path $TestDrive -ChildPath 'missing'

        { Invoke-WUDefaultBrowserDownload -Uri 'https://example.com/file.zip' -DownloadDirectory $missingDirectory } |
            Should -Throw '*does not exist*'
    }

    It 'requires Force when the target file exists' {
        $targetPath = Join-Path -Path $TestDrive -ChildPath 'file.zip'
        [IO.File]::WriteAllText($targetPath, 'existing')

        { Invoke-WUDefaultBrowserDownload -Uri 'https://example.com/file.zip' -DownloadDirectory $TestDrive } |
            Should -Throw '*Use Force*'
    }

    It 'forwards Force and timeout to the internal operation' {
        $targetPath = Join-Path -Path $TestDrive -ChildPath 'file.zip'
        [IO.File]::WriteAllText($targetPath, 'existing')

        Invoke-WUDefaultBrowserDownload -Uri 'https://example.com/file.zip' -DownloadDirectory $TestDrive -TimeoutSeconds 30 -Force

        Should -Invoke -CommandName Invoke-WUDefaultBrowserDownloadInternal -ModuleName PSWinUtil -Times 1 -Exactly -ParameterFilter {
            $Force -and $TimeoutSeconds -eq 30
        }
    }

    It 'does not start the internal operation with WhatIf' {
        Invoke-WUDefaultBrowserDownload -Uri 'https://example.com/file.zip' -DownloadDirectory $TestDrive -WhatIf

        Should -Invoke -CommandName Invoke-WUDefaultBrowserDownloadInternal -ModuleName PSWinUtil -Times 0 -Exactly
    }
}

Describe 'Invoke-WUDefaultBrowserDownloadInternal' {
    BeforeEach {
        Get-ChildItem -LiteralPath $TestDrive -File | Remove-Item -Force
        $script:BrowserTargetPath = Join-Path -Path $TestDrive -ChildPath 'package.zip'
        $script:BrowserFileContent = 'downloaded'
        $script:BrowserLockStream = $null
        Mock -CommandName Start-Process -ModuleName PSWinUtil -MockWith {
            [IO.File]::WriteAllText($script:BrowserTargetPath, $script:BrowserFileContent)
        }
    }

    AfterEach {
        if ($null -ne $script:BrowserLockStream) {
            $script:BrowserLockStream.Dispose()
        }
    }

    It 'returns the completed file path' {
        $parameters = @{
            Uri = 'https://example.com/package.zip'
            FileName = 'package.zip'
            DownloadDirectory = $TestDrive
            TimeoutSeconds = 2
        }
        $result = InModuleScope -ModuleName PSWinUtil -Parameters @{ InvokeParameters = $parameters } {
            Invoke-WUDefaultBrowserDownloadInternal @InvokeParameters
        }

        $result | Should -Be $script:BrowserTargetPath
        [IO.File]::ReadAllText($result) | Should -Be 'downloaded'
    }

    It 'replaces an existing target only with Force' {
        [IO.File]::WriteAllText($script:BrowserTargetPath, 'old')
        $parameters = @{
            Uri = 'https://example.com/package.zip'
            FileName = 'package.zip'
            DownloadDirectory = $TestDrive
            TimeoutSeconds = 2
            Force = $true
        }

        InModuleScope -ModuleName PSWinUtil -Parameters @{ InvokeParameters = $parameters } {
            Invoke-WUDefaultBrowserDownloadInternal @InvokeParameters
        }

        [IO.File]::ReadAllText($script:BrowserTargetPath) | Should -Be 'downloaded'
    }

    It 'removes browser partial files before starting' {
        $chromePartialPath = "$($script:BrowserTargetPath).crdownload"
        $firefoxPartialPath = "$($script:BrowserTargetPath).part"
        [IO.File]::WriteAllText($chromePartialPath, 'partial')
        [IO.File]::WriteAllText($firefoxPartialPath, 'partial')
        $parameters = @{
            Uri = 'https://example.com/package.zip'
            FileName = 'package.zip'
            DownloadDirectory = $TestDrive
            TimeoutSeconds = 2
        }

        InModuleScope -ModuleName PSWinUtil -Parameters @{ InvokeParameters = $parameters } {
            Invoke-WUDefaultBrowserDownloadInternal @InvokeParameters
        }

        Test-Path -LiteralPath $chromePartialPath | Should -BeFalse
        Test-Path -LiteralPath $firefoxPartialPath | Should -BeFalse
    }

    It 'waits while the target file is locked and then times out' {
        Mock -CommandName Start-Process -ModuleName PSWinUtil -MockWith {
            [IO.File]::WriteAllText($script:BrowserTargetPath, 'locked')
            $script:BrowserLockStream = [IO.File]::Open(
                $script:BrowserTargetPath,
                [IO.FileMode]::Open,
                [IO.FileAccess]::Read,
                [IO.FileShare]::None
            )
        }
        $parameters = @{
            Uri = 'https://example.com/package.zip'
            FileName = 'package.zip'
            DownloadDirectory = $TestDrive
            TimeoutSeconds = 1
        }

        {
            InModuleScope -ModuleName PSWinUtil -Parameters @{ InvokeParameters = $parameters } {
                Invoke-WUDefaultBrowserDownloadInternal @InvokeParameters
            }
        } | Should -Throw '*did not complete*'
    }

    It 'times out when the target file is not created' {
        Mock -CommandName Start-Process -ModuleName PSWinUtil
        $parameters = @{
            Uri = 'https://example.com/package.zip'
            FileName = 'package.zip'
            DownloadDirectory = $TestDrive
            TimeoutSeconds = 1
        }

        {
            InModuleScope -ModuleName PSWinUtil -Parameters @{ InvokeParameters = $parameters } {
                Invoke-WUDefaultBrowserDownloadInternal @InvokeParameters
            }
        } | Should -Throw '*did not complete*'
    }
}
