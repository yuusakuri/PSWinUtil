BeforeAll {
    . (Join-Path -Path $PSScriptRoot -ChildPath '../UnitTestBootstrap.ps1')

    $script:Module = Get-Module -Name 'PSWinUtil' -ErrorAction Stop

    Add-Type -AssemblyName 'System.Net.Http' -ErrorAction Stop
    if ($null -eq ('PSWinUtil.Tests.StaticHttpMessageHandler' -as [type])) {
        $testSupportTargetFramework = 'netstandard2.0'
        if ($PSVersionTable.PSEdition -eq 'Desktop') {
            $testSupportTargetFramework = 'net472'
        }

        $testSupportAssemblyPath = Join-Path `
            -Path $repositoryRoot `
            -ChildPath "output/TestSupport/$testSupportTargetFramework/PSWinUtil.TestSupport.dll"
        if (-not (Test-Path -LiteralPath $testSupportAssemblyPath -PathType Leaf)) {
            throw ".\dev.ps1 build must run before the tests: $testSupportAssemblyPath"
        }

        Add-Type -LiteralPath $testSupportAssemblyPath -ErrorAction Stop
    }
}

Describe 'Invoke-WUHttpFileDownload' {
    BeforeEach {
        $script:ResponseBody = [System.Text.Encoding]::UTF8.GetBytes('download body')
        $script:Handler = [PSWinUtil.Tests.StaticHttpMessageHandler]::new(
            $script:ResponseBody,
            [System.Net.HttpStatusCode]::OK
        )
        $script:Client = [System.Net.Http.HttpClient]::new($script:Handler)
        & $script:Module {
            param($Client)

            $script:WUHttpClient = $Client
        } $script:Client
    }

    AfterEach {
        & $script:Module {
            $script:WUHttpClient = $null
        }
        $script:Client.Dispose()
    }

    It 'is public and has no retry or timeout parameter' {
        $command = Get-Command -Name Invoke-WUHttpFileDownload -Module PSWinUtil

        $command | Should -Not -BeNullOrEmpty
        $command.Parameters.Keys | Should -Contain 'Uri'
        $command.Parameters.Keys | Should -Contain 'Path'
        $command.Parameters.Keys | Should -Not -Contain 'RetryCount'
        $command.Parameters.Keys | Should -Not -Contain 'TimeoutSeconds'
    }

    It 'downloads a new file without a range request' {
        $path = Join-Path -Path $TestDrive -ChildPath 'package.zip'

        $result = Invoke-WUHttpFileDownload `
            -Uri 'https://example.com/package.zip' `
            -Path $path

        $result | Should -Be ([System.IO.Path]::GetFullPath($path))
        [System.IO.File]::ReadAllBytes($path) | Should -Be $script:ResponseBody
        $script:Handler.RequestUri.AbsoluteUri | Should -Be 'https://example.com/package.zip'
        $script:Handler.RangeStart | Should -BeNullOrEmpty
    }

    It 'requests an existing file length and restarts when the server returns OK' {
        $path = Join-Path -Path $TestDrive -ChildPath 'partial.zip'
        [System.IO.File]::WriteAllText($path, 'partial')

        Invoke-WUHttpFileDownload `
            -Uri 'https://example.com/package.zip' `
            -Path $path

        $script:Handler.RangeStart | Should -Be 7
        [System.IO.File]::ReadAllBytes($path) | Should -Be $script:ResponseBody
    }

    It 'preserves a partial file when an HTTP failure makes no progress' {
        $script:Client.Dispose()
        $script:Handler = [PSWinUtil.Tests.StaticHttpMessageHandler]::new(
            [byte[]]@(),
            [System.Net.HttpStatusCode]::BadGateway
        )
        $script:Client = [System.Net.Http.HttpClient]::new($script:Handler)
        & $script:Module {
            param($Client)

            $script:WUHttpClient = $Client
        } $script:Client
        $path = Join-Path -Path $TestDrive -ChildPath 'failed.zip'
        [System.IO.File]::WriteAllText($path, 'partial')

        {
            Invoke-WUHttpFileDownload `
                -Uri 'https://example.com/failed.zip' `
                -Path $path
        } | Should -Throw

        [System.IO.File]::ReadAllText($path) | Should -Be 'partial'
        $script:Handler.RangeStart | Should -Be 7
    }

    It 'does not send a request with WhatIf' {
        $path = Join-Path -Path $TestDrive -ChildPath 'whatif.zip'

        Invoke-WUHttpFileDownload `
            -Uri 'https://example.com/package.zip' `
            -Path $path `
            -WhatIf

        Test-Path -LiteralPath $path | Should -BeFalse
        $script:Handler.RequestUri | Should -BeNullOrEmpty
    }
}
