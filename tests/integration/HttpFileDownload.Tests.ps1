BeforeAll {
    . (Join-Path -Path $PSScriptRoot -ChildPath '../UnitTestBootstrap.ps1')

    if ($null -eq ('PSWinUtil.Tests.DownloadInterruptionServer' -as [type])) {
        $fakeHttpServerTargetFramework = 'netstandard2.0'
        if ($PSVersionTable.PSEdition -eq 'Desktop') {
            $fakeHttpServerTargetFramework = 'net472'
        }

        $fakeHttpServerAssemblyPathParameters = @{
            Path = $repositoryRoot
            ChildPath = "output/FakeHttpServer/$fakeHttpServerTargetFramework/PSWinUtil.FakeHttpServer.dll"
        }
        $fakeHttpServerAssemblyPath = Join-Path @fakeHttpServerAssemblyPathParameters
        if (-not (Test-Path -LiteralPath $fakeHttpServerAssemblyPath -PathType Leaf)) {
            throw ".\dev.ps1 build must run before the tests: $fakeHttpServerAssemblyPath"
        }

        Add-Type -LiteralPath $fakeHttpServerAssemblyPath -ErrorAction Stop
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
        $server = [PSWinUtil.Tests.DownloadInterruptionServer]::new(
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
            ($server.RangeStarts | Select-Object -First 1) | Should -Be -1
            $server.RangeStarts[1] | Should -Be $firstLength
            $server.ServerException | Should -BeNullOrEmpty
        } finally {
            $server.Dispose()
        }
    }

    It 'resumes from each new position after multiple interruptions' {
        $firstLength = [int]($script:SourceBytes.Length / 4)
        $secondLength = [int]($script:SourceBytes.Length / 5)
        $server = [PSWinUtil.Tests.DownloadInterruptionServer]::new(
            $script:SourceBytes,
            [int[]]@($firstLength, $secondLength)
        )
        try {
            Invoke-WUHttpFileDownload -Uri $server.Uri -Path $script:DownloadPath

            (Get-FileHash -LiteralPath $script:DownloadPath -Algorithm SHA256).Hash |
                Should -Be $script:ExpectedHash
            $server.RangeStarts | Should -HaveCount 3
            ($server.RangeStarts | Select-Object -First 1) | Should -Be -1
            $server.RangeStarts[1] | Should -Be $firstLength
            $server.RangeStarts[2] | Should -Be ($firstLength + $secondLength)
            $server.ServerException | Should -BeNullOrEmpty
        } finally {
            $server.Dispose()
        }
    }

    It 'stops when a resumed response writes no data' {
        $firstLength = [int]($script:SourceBytes.Length / 3)
        $server = [PSWinUtil.Tests.DownloadInterruptionServer]::new(
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

    It 'rejects a file as the destination parent before sending a request' {
        $parentFilePath = Join-Path -Path $TestDrive -ChildPath 'destination-parent'
        [System.IO.File]::WriteAllText($parentFilePath, 'not a directory')
        $destinationPath = Join-Path -Path $parentFilePath -ChildPath 'download.zip'
        $server = [PSWinUtil.Tests.DownloadInterruptionServer]::new(
            [byte[]]@(1, 2, 3),
            [int[]]@()
        )

        try {
            {
                Invoke-WUHttpFileDownload -Uri $server.Uri -Path $destinationPath
            } | Should -Throw

            $server.RangeStarts | Should -HaveCount 0
        } finally {
            $server.Dispose()
        }
    }

    It 'creates missing destination parent directories before downloading' {
        $destinationDirectory = Join-Path -Path $TestDrive -ChildPath 'created/child'
        $destinationPath = Join-Path -Path $destinationDirectory -ChildPath 'download.bin'
        $payload = [byte[]]@(1, 2, 3, 4)
        $server = [PSWinUtil.Tests.DownloadInterruptionServer]::new($payload, [int[]]@())

        try {
            $result = Invoke-WUHttpFileDownload -Uri $server.Uri -Path $destinationPath

            $result | Should -Be $destinationPath
            Test-Path -LiteralPath $destinationDirectory -PathType Container | Should -BeTrue
            [System.IO.File]::ReadAllBytes($destinationPath) | Should -Be $payload
            $server.RangeStarts | Should -HaveCount 1
        } finally {
            $server.Dispose()
        }
    }
}
