BeforeAll {
    $repositoryRoot = Split-Path -Path (Split-Path -Path $PSScriptRoot -Parent) -Parent
    $manifestPath = Join-Path -Path $repositoryRoot -ChildPath 'output/PSWinUtil/PSWinUtil.psd1'
    Import-Module -Name $manifestPath -Force -ErrorAction Stop
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
            throw "Run .\run.ps1 build before running the tests. The test support assembly was not found: $testSupportAssemblyPath"
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

    It 'downloads a response body without a browser' {
        $path = Join-Path -Path $TestDrive -ChildPath 'package.zip'

        $result = & $script:Module {
            param($Path)

            Invoke-WUHttpFileDownload `
                -Uri 'https://example.com/package.zip' `
                -Path $Path `
                -TimeoutSeconds 30
        } $path

        $result | Should -Be ([System.IO.Path]::GetFullPath($path))
        [System.IO.File]::ReadAllBytes($path) | Should -Be $script:ResponseBody
        $script:Handler.RequestUri.AbsoluteUri | Should -Be 'https://example.com/package.zip'
    }

    It 'removes an incomplete file after an HTTP error' {
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

        {
            & $script:Module {
                param($Path)

                Invoke-WUHttpFileDownload `
                    -Uri 'https://example.com/failed.zip' `
                    -Path $Path `
                    -TimeoutSeconds 30
            } $path
        } | Should -Throw

        Test-Path -LiteralPath $path | Should -BeFalse
    }

    It 'does not replace an existing target' {
        $path = Join-Path -Path $TestDrive -ChildPath 'existing.zip'
        [System.IO.File]::WriteAllText($path, 'existing')

        {
            & $script:Module {
                param($Path)

                Invoke-WUHttpFileDownload `
                    -Uri 'https://example.com/package.zip' `
                    -Path $Path `
                    -TimeoutSeconds 30
            } $path
        } | Should -Throw '*already exists*'

        [System.IO.File]::ReadAllText($path) | Should -Be 'existing'
        $script:Handler.RequestUri | Should -BeNullOrEmpty
    }
}
