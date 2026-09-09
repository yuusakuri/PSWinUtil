BeforeAll {
    . (Join-Path -Path $PSScriptRoot -ChildPath '../UnitTestBootstrap.ps1')

    if ($null -eq ('PSWinUtil.Tests.DisconnectingHttpServer' -as [type])) {
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

Describe 'Resumable HTTP download' {
    BeforeEach {
        $payloadPath = Join-Path -Path $TestDrive -ChildPath 'payload.bin'
        $script:SourcePath = Join-Path -Path $TestDrive -ChildPath 'source.zip'
        $script:DownloadPath = Join-Path -Path $TestDrive -ChildPath 'download.zip'
        Remove-Item -LiteralPath $script:SourcePath -Force -ErrorAction Ignore
        Remove-Item -LiteralPath $script:DownloadPath -Force -ErrorAction Ignore
        $payload = [byte[]]::new(1048576)
        [System.Random]::new(12345).NextBytes($payload)
        [System.IO.File]::WriteAllBytes($payloadPath, $payload)
        Compress-Archive -LiteralPath $payloadPath -DestinationPath $script:SourcePath
        $script:SourceBytes = [System.IO.File]::ReadAllBytes($script:SourcePath)
        $script:ExpectedHash = (Get-FileHash -LiteralPath $script:SourcePath -Algorithm SHA256).Hash
    }

    It 'resumes after one interrupted response' {
        $firstLength = [int]($script:SourceBytes.Length / 3)
        $server = [PSWinUtil.Tests.DisconnectingHttpServer]::new(
            $script:SourceBytes,
            [int[]]@($firstLength)
        )
        try {
            Invoke-WUHttpFileDownload -Uri $server.Uri -Path $script:DownloadPath

            (Get-FileHash -LiteralPath $script:DownloadPath -Algorithm SHA256).Hash |
                Should -Be $script:ExpectedHash
            (Get-Item -LiteralPath $script:DownloadPath).Length |
                Should -Be (Get-Item -LiteralPath $script:SourcePath).Length
            $server.RangeStarts | Should -HaveCount 2
            $server.RangeStarts[0] | Should -Be -1
            $server.RangeStarts[1] | Should -Be $firstLength
            $server.ServerException | Should -BeNullOrEmpty
        } finally {
            $server.Dispose()
        }
    }

    It 'resumes from each new position after multiple interruptions' {
        $firstLength = [int]($script:SourceBytes.Length / 4)
        $secondLength = [int]($script:SourceBytes.Length / 5)
        $server = [PSWinUtil.Tests.DisconnectingHttpServer]::new(
            $script:SourceBytes,
            [int[]]@($firstLength, $secondLength)
        )
        try {
            Invoke-WUHttpFileDownload -Uri $server.Uri -Path $script:DownloadPath

            (Get-FileHash -LiteralPath $script:DownloadPath -Algorithm SHA256).Hash |
                Should -Be $script:ExpectedHash
            $server.RangeStarts | Should -HaveCount 3
            $server.RangeStarts[0] | Should -Be -1
            $server.RangeStarts[1] | Should -Be $firstLength
            $server.RangeStarts[2] | Should -Be ($firstLength + $secondLength)
            $server.ServerException | Should -BeNullOrEmpty
        } finally {
            $server.Dispose()
        }
    }

    It 'stops when a resumed response writes no data' {
        $firstLength = [int]($script:SourceBytes.Length / 3)
        $server = [PSWinUtil.Tests.DisconnectingHttpServer]::new(
            $script:SourceBytes,
            [int[]]@($firstLength, 0)
        )
        try {
            {
                Invoke-WUHttpFileDownload -Uri $server.Uri -Path $script:DownloadPath
            } | Should -Throw

            (Get-Item -LiteralPath $script:DownloadPath).Length | Should -Be $firstLength
            $server.RangeStarts | Should -HaveCount 2
            $server.RangeStarts[1] | Should -Be $firstLength
            $server.ServerException | Should -BeNullOrEmpty
        } finally {
            $server.Dispose()
        }
    }
}
