BeforeAll {
    . (Join-Path -Path $PSScriptRoot -ChildPath '../UnitTestBootstrap.ps1')

    $script:Utf8NoBom = [System.Text.UTF8Encoding]::new($false)
    $script:UnicodeText = [string][char]0x3042
    $script:AssertSameFileBytes = {
        param([string]$ProxyPath, [string]$OriginalPath)

        [Convert]::ToBase64String([System.IO.File]::ReadAllBytes($ProxyPath)) |
            Should -Be ([Convert]::ToBase64String([System.IO.File]::ReadAllBytes($OriginalPath)))
    }
    $script:AssertUtf8Lf = {
        param([string]$Path)

        [byte[]]$bytes = [System.IO.File]::ReadAllBytes($Path)
        if ($bytes.Length -ge 3) {
            $bytes[0..2] | Should -Not -Be @(0xEF, 0xBB, 0xBF)
        }
        $bytes | Should -Not -Contain 0x0D
        [System.IO.File]::ReadAllText($Path, $script:Utf8NoBom)
    }
}

$contentCommandOverridesAvailable = $PSVersionTable.PSEdition -eq 'Desktop'

Describe 'Content command precedence' -Skip:(-not $contentCommandOverridesAvailable) {
    It 'uses the PSWinUtil functions before the built-in cmdlets' {
        foreach ($commandName in @(
                'Get-Content'
                'Set-Content'
                'Add-Content'
                'Out-File'
                'Invoke-WebRequest'
            )) {
            $command = Get-Command -Name $commandName
            $command.CommandType | Should -Be 'Function'
            $command.ModuleName | Should -Be 'PSWinUtil'
            @(Get-Command -Name $commandName -All | Where-Object { $_.CommandType -eq 'Cmdlet' }).Count |
                Should -BeGreaterThan 0
        }
    }

    It 'keeps the original content cmdlet parameter names' {
        foreach ($commandName in @('Get-Content', 'Set-Content', 'Add-Content')) {
            $proxyParameters = @((Get-Command -Name $commandName -Module PSWinUtil).Parameters.Keys | Sort-Object)
            $originalParameters = @(
                (Get-Command -Name "Microsoft.PowerShell.Management\$commandName").Parameters.Keys |
                    Sort-Object
            )
            Compare-Object -ReferenceObject $originalParameters -DifferenceObject $proxyParameters |
                Should -BeNullOrEmpty
        }

        $proxyParameters = @((Get-Command -Name Out-File -Module PSWinUtil).Parameters.Keys | Sort-Object)
        $originalParameters = @(
            (Get-Command -Name 'Microsoft.PowerShell.Utility\Out-File').Parameters.Keys |
                Sort-Object
        )
        Compare-Object -ReferenceObject $originalParameters -DifferenceObject $proxyParameters |
            Should -BeNullOrEmpty

        $proxyParameters = @((Get-Command -Name Invoke-WebRequest -Module PSWinUtil).Parameters.Keys | Sort-Object)
        $originalParameters = @(
            (Get-Command -Name 'Microsoft.PowerShell.Utility\Invoke-WebRequest').Parameters.Keys |
                Sort-Object
        )
        Compare-Object -ReferenceObject $originalParameters -DifferenceObject $proxyParameters |
            Should -BeNullOrEmpty
    }
}

Describe 'Invoke-WebRequest progress suppression' -Skip:(-not $contentCommandOverridesAvailable) {
    It 'gets an HTTP response and restores ProgressPreference' {
        $portProbe = [System.Net.Sockets.TcpListener]::new(
            [System.Net.IPAddress]::Loopback,
            0
        )
        $portProbe.Start()
        $availablePort = ([System.Net.IPEndPoint]$portProbe.LocalEndpoint).Port
        $portProbe.Stop()

        $serverJob = Start-Job -ArgumentList $availablePort -ScriptBlock {
            $serverPort = [int]$args[0]

            $listener = [System.Net.Sockets.TcpListener]::new(
                [System.Net.IPAddress]::Loopback,
                $serverPort
            )
            try {
                $listener.Start()
                Write-Output 'READY'
                $client = $listener.AcceptTcpClient()
                try {
                    $stream = $client.GetStream()
                    $reader = [System.IO.StreamReader]::new($stream)
                    while ($reader.ReadLine() -ne '') {
                    }

                    [byte[]]$responseBytes = [System.Text.Encoding]::ASCII.GetBytes(
                        "HTTP/1.1 200 OK`r`n" +
                        "Content-Type: text/plain`r`n" +
                        "Content-Length: 2`r`n" +
                        "Connection: close`r`n`r`nOK"
                    )
                    $stream.Write($responseBytes, 0, $responseBytes.Length)
                    $stream.Flush()
                } finally {
                    $client.Dispose()
                }
            } finally {
                $listener.Stop()
            }
        }

        try {
            $readyDeadline = [datetime]::UtcNow.AddSeconds(10)
            do {
                $serverOutput = @(Receive-Job -Job $serverJob -Keep)
                if ($serverOutput -contains 'READY') {
                    break
                }
                Start-Sleep -Milliseconds 20
            } while ([datetime]::UtcNow -lt $readyDeadline)
            $serverOutput | Should -Contain 'READY'

            $originalProgressPreference = $ProgressPreference
            $ProgressPreference = 'Continue'
            try {
                $response = Invoke-WebRequest `
                    -Uri "http://127.0.0.1:$availablePort/" `
                    -UseBasicParsing `
                    -ErrorAction Stop

                $response.StatusCode | Should -Be 200
                $response.Content | Should -Be 'OK'
                $ProgressPreference | Should -Be 'Continue'
            } finally {
                $ProgressPreference = $originalProgressPreference
            }

            Wait-Job -Job $serverJob -Timeout 10 | Should -Not -BeNullOrEmpty
            $serverJob.State | Should -Be 'Completed'
        } finally {
            Stop-Job -Job $serverJob -ErrorAction SilentlyContinue
            Remove-Job -Job $serverJob -Force -ErrorAction SilentlyContinue
        }
    }

    It 'restores ProgressPreference when the delegated request fails' {
        $originalProgressPreference = $ProgressPreference
        $ProgressPreference = 'Continue'
        try {
            {
                Invoke-WebRequest `
                    -Uri 'http://127.0.0.1:1/' `
                    -UseBasicParsing `
                    -TimeoutSec 1 `
                    -ErrorAction Stop
            } | Should -Throw

            $ProgressPreference | Should -Be 'Continue'
        } finally {
            $ProgressPreference = $originalProgressPreference
        }
    }
}

Describe 'Get-Content UTF-8 default' -Skip:(-not $contentCommandOverridesAvailable) {
    It 'reads UTF-8 without BOM when Encoding is omitted' {
        $path = Join-Path -Path $TestDrive -ChildPath 'read.txt'
        [System.IO.File]::WriteAllText($path, $script:UnicodeText, $script:Utf8NoBom)

        Get-Content -LiteralPath $path -Raw | Should -Be $script:UnicodeText
    }

    It 'keeps an explicit encoding override' {
        $path = Join-Path -Path $TestDrive -ChildPath 'read-unicode.txt'
        [System.IO.File]::WriteAllText($path, $script:UnicodeText, [System.Text.Encoding]::Unicode)

        Get-Content -LiteralPath $path -Raw -Encoding Unicode | Should -Be $script:UnicodeText
    }
}

Describe 'Set-Content UTF-8 and LF default' -Skip:(-not $contentCommandOverridesAvailable) {
    It 'writes UTF-8 without BOM and LF' {
        $path = Join-Path -Path $TestDrive -ChildPath 'set.txt'

        Set-Content -LiteralPath $path -Value @($script:UnicodeText, 'second')

        $content = & $script:AssertUtf8Lf -Path $path
        $content | Should -Be "$($script:UnicodeText)`nsecond`n"
    }

    It 'does not write with WhatIf' {
        $path = Join-Path -Path $TestDrive -ChildPath 'set-what-if.txt'

        Set-Content -LiteralPath $path -Value 'content' -WhatIf

        Test-Path -LiteralPath $path | Should -BeFalse
    }

    It 'keeps an explicit non-UTF8 encoding' {
        $path = Join-Path -Path $TestDrive -ChildPath 'set-unicode.txt'

        Set-Content -LiteralPath $path -Value $script:UnicodeText -Encoding Unicode

        [byte[]]$bytes = [System.IO.File]::ReadAllBytes($path)
        $bytes[0] | Should -Be 0xFF
        $bytes[1] | Should -Be 0xFE
    }
}

Describe 'Add-Content UTF-8 and LF default' -Skip:(-not $contentCommandOverridesAvailable) {
    It 'converts existing Unicode content and appends UTF-8 with LF' {
        $path = Join-Path -Path $TestDrive -ChildPath 'add.txt'
        [System.IO.File]::WriteAllText($path, "first`r`n", [System.Text.Encoding]::Unicode)

        Add-Content -LiteralPath $path -Value $script:UnicodeText

        $content = & $script:AssertUtf8Lf -Path $path
        $content | Should -Be "first`n$($script:UnicodeText)`n"
    }
}

Describe 'Out-File UTF-8 and LF default' -Skip:(-not $contentCommandOverridesAvailable) {
    It 'writes formatted text as UTF-8 without BOM and LF' {
        $path = Join-Path -Path $TestDrive -ChildPath 'out.txt'

        @($script:UnicodeText, 'second') | Out-File -LiteralPath $path

        $content = & $script:AssertUtf8Lf -Path $path
        $content | Should -Be "$($script:UnicodeText)`nsecond`n"
    }

    It 'appends to an existing Unicode file and converts it' {
        $path = Join-Path -Path $TestDrive -ChildPath 'out-append.txt'
        [System.IO.File]::WriteAllText($path, "first`r`n", [System.Text.Encoding]::Unicode)

        $script:UnicodeText | Out-File -LiteralPath $path -Append

        $content = & $script:AssertUtf8Lf -Path $path
        $content | Should -Be "first`n$($script:UnicodeText)`n"
    }

    It 'does not write with WhatIf' {
        $path = Join-Path -Path $TestDrive -ChildPath 'out-what-if.txt'

        'content' | Out-File -LiteralPath $path -WhatIf

        Test-Path -LiteralPath $path | Should -BeFalse
    }

    It 'writes without line separators with NoNewline' {
        $path = Join-Path -Path $TestDrive -ChildPath 'out-no-newline.txt'

        @('first', 'second') | Out-File -LiteralPath $path -NoNewline

        [System.IO.File]::ReadAllText($path, $script:Utf8NoBom) | Should -Be 'firstsecond'
    }

    It 'keeps an explicit non-UTF8 encoding' {
        $path = Join-Path -Path $TestDrive -ChildPath 'out-unicode.txt'

        $script:UnicodeText | Out-File -LiteralPath $path -Encoding Unicode

        [byte[]]$bytes = [System.IO.File]::ReadAllBytes($path)
        $bytes[0] | Should -Be 0xFF
        $bytes[1] | Should -Be 0xFE
    }

    It 'does not replace an existing file with NoClobber' {
        $path = Join-Path -Path $TestDrive -ChildPath 'out-no-clobber.txt'
        [System.IO.File]::WriteAllText($path, 'existing', $script:Utf8NoBom)

        { 'new' | Out-File -LiteralPath $path -NoClobber } | Should -Throw

        [System.IO.File]::ReadAllText($path, $script:Utf8NoBom) | Should -Be 'existing'
    }
}

Describe 'Command override state' -Skip:(-not $contentCommandOverridesAvailable) {
    BeforeAll {
        $script:GetOverrideState = {
            param([string]$Name)

            & (Get-Module -Name 'PSWinUtil') {
                param($OverriddenCommandName)

                Test-WUCommandOverrideEnabled -Name $OverriddenCommandName
            } $Name
        }
    }

    AfterEach {
        Enable-WUGetContentOverride
        Enable-WUSetContentOverride
        Enable-WUAddContentOverride
        Enable-WUOutFileOverride
        Enable-WUInvokeWebRequestOverride
    }

    It 'enables every override before it is changed' {
        foreach ($commandName in @(
                'Get-Content'
                'Set-Content'
                'Add-Content'
                'Out-File'
                'Invoke-WebRequest'
            )) {
            & $script:GetOverrideState -Name $commandName | Should -BeTrue
        }
    }

    It 'changes only the command named by the state command' {
        Disable-WUInvokeWebRequestOverride

        & $script:GetOverrideState -Name 'Invoke-WebRequest' | Should -BeFalse
        foreach ($commandName in @(
                'Get-Content'
                'Set-Content'
                'Add-Content'
                'Out-File'
            )) {
            & $script:GetOverrideState -Name $commandName | Should -BeTrue
        }

        Enable-WUInvokeWebRequestOverride
        & $script:GetOverrideState -Name 'Invoke-WebRequest' | Should -BeTrue
    }

    It 'keeps the state with WhatIf' {
        Disable-WUGetContentOverride -WhatIf

        & $script:GetOverrideState -Name 'Get-Content' | Should -BeTrue
    }

    It 'reads like the original cmdlet while the Get-Content override is disabled' {
        $path = Join-Path -Path $TestDrive -ChildPath 'state-get.txt'
        [System.IO.File]::WriteAllText($path, $script:UnicodeText, $script:Utf8NoBom)

        Disable-WUGetContentOverride
        Get-Content -LiteralPath $path -Raw |
            Should -Be (Microsoft.PowerShell.Management\Get-Content -LiteralPath $path -Raw)

        Enable-WUGetContentOverride
        Get-Content -LiteralPath $path -Raw | Should -Be $script:UnicodeText
    }

    It 'writes like the original cmdlet while the Set-Content override is disabled' {
        $proxyPath = Join-Path -Path $TestDrive -ChildPath 'state-set-proxy.txt'
        $originalPath = Join-Path -Path $TestDrive -ChildPath 'state-set-original.txt'

        Disable-WUSetContentOverride
        Set-Content -LiteralPath $proxyPath -Value @($script:UnicodeText, 'second')
        Microsoft.PowerShell.Management\Set-Content `
            -LiteralPath $originalPath `
            -Value @($script:UnicodeText, 'second')

        & $script:AssertSameFileBytes -ProxyPath $proxyPath -OriginalPath $originalPath
    }

    It 'appends like the original cmdlet while the Add-Content override is disabled' {
        $proxyPath = Join-Path -Path $TestDrive -ChildPath 'state-add-proxy.txt'
        $originalPath = Join-Path -Path $TestDrive -ChildPath 'state-add-original.txt'
        foreach ($path in @($proxyPath, $originalPath)) {
            [System.IO.File]::WriteAllText($path, "first`r`n", [System.Text.Encoding]::Unicode)
        }

        Disable-WUAddContentOverride
        Add-Content -LiteralPath $proxyPath -Value 'second'
        Microsoft.PowerShell.Management\Add-Content -LiteralPath $originalPath -Value 'second'

        & $script:AssertSameFileBytes -ProxyPath $proxyPath -OriginalPath $originalPath
    }

    It 'writes like the original cmdlet while the Out-File override is disabled' {
        $proxyPath = Join-Path -Path $TestDrive -ChildPath 'state-out-proxy.txt'
        $originalPath = Join-Path -Path $TestDrive -ChildPath 'state-out-original.txt'

        Disable-WUOutFileOverride
        @($script:UnicodeText, 'second') | Out-File -LiteralPath $proxyPath
        @($script:UnicodeText, 'second') |
            Microsoft.PowerShell.Utility\Out-File -LiteralPath $originalPath

        & $script:AssertSameFileBytes -ProxyPath $proxyPath -OriginalPath $originalPath
    }

    It 'sends a request while the Invoke-WebRequest override is disabled' {
        Disable-WUInvokeWebRequestOverride

        $originalProgressPreference = $ProgressPreference
        $ProgressPreference = 'Continue'
        try {
            {
                Invoke-WebRequest `
                    -Uri 'http://127.0.0.1:1/' `
                    -UseBasicParsing `
                    -TimeoutSec 1 `
                    -ErrorAction Stop
            } | Should -Throw

            $ProgressPreference | Should -Be 'Continue'
        } finally {
            $ProgressPreference = $originalProgressPreference
        }
    }
}
