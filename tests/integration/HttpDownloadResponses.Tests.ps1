BeforeAll {
    . (Join-Path -Path $PSScriptRoot -ChildPath '../UnitTestBootstrap.ps1')
    Add-Type -LiteralPath (Join-Path $repositoryRoot 'output/TestSupport/net472/PSWinUtil.TestSupport.dll')
}

Describe 'HTTP download transport integration' {
    BeforeEach {
        $script:Body = [Text.Encoding]::UTF8.GetBytes(('download content' * 10000))
        $script:Server = [PSWinUtil.Tests.LoopbackHttpServer]::new($script:Body)
        $script:Destination = Join-Path $TestDrive ([guid]::NewGuid().ToString('N') + '.bin')
    }

    AfterEach {
        $script:Server.Dispose()
    }

    It 'downloads exact bytes through HttpClient and the file system' {
        $result = Invoke-WUHttpFileDownload -Uri $script:Server.BaseUri -Path $script:Destination
        $result | Should -Be $script:Destination
        [Convert]::ToBase64String([IO.File]::ReadAllBytes($result)) |
            Should -Be ([Convert]::ToBase64String($script:Body))
    }

    It 'completes a partial file when the server <Mode>' -TestCases @(
        @{ Mode = 'resume' }
        @{ Mode = 'ignore' }
    ) {
        param($Mode)
        [IO.File]::WriteAllBytes($script:Destination, $script:Body[0..99])
        $uri = [uri]::new($script:Server.BaseUri, $Mode)
        $null = Invoke-WUHttpFileDownload -Uri $uri -Path $script:Destination
        [Convert]::ToBase64String([IO.File]::ReadAllBytes($script:Destination)) |
            Should -Be ([Convert]::ToBase64String($script:Body))
    }

    It 'resumes automatically after a connection closes during transfer' {
        $uri = [uri]::new($script:Server.BaseUri, 'interrupt')
        $null = Invoke-WUHttpFileDownload -Uri $uri -Path $script:Destination
        [Convert]::ToBase64String([IO.File]::ReadAllBytes($script:Destination)) |
            Should -Be ([Convert]::ToBase64String($script:Body))
    }

    It 'preserves saved bytes after <Mode> without leaving the file locked' -TestCases @(
        @{ Mode = 'fail' }
        @{ Mode = 'invalid' }
    ) {
        param($Mode)
        [IO.File]::WriteAllText($script:Destination, 'saved')
        $uri = [uri]::new($script:Server.BaseUri, $Mode)
        { Invoke-WUHttpFileDownload -Uri $uri -Path $script:Destination } | Should -Throw
        [IO.File]::ReadAllText($script:Destination) | Should -Be 'saved'
        $handle = [IO.File]::Open($script:Destination, 'Open', 'ReadWrite', 'None')
        $handle.Dispose()
    }

    It 'does not create a file with WhatIf' {
        Invoke-WUHttpFileDownload -Uri $script:Server.BaseUri -Path $script:Destination -WhatIf
        Test-Path -LiteralPath $script:Destination | Should -BeFalse
    }
}
