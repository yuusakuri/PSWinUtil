BeforeAll {
    . (Join-Path -Path $PSScriptRoot -ChildPath '../UnitTestBootstrap.ps1')

    $script:Utf8NoBom = [System.Text.UTF8Encoding]::new($false)
    $script:UnicodeText = [string][char]0x3042
    $script:OverrideNames = @('Get-Content', 'Set-Content', 'Add-Content', 'Out-File')
    function Assert-PSWinUtilFileByteEquality {
        param([string]$ProxyPath, [string]$OriginalPath)

        [Convert]::ToBase64String([System.IO.File]::ReadAllBytes($ProxyPath)) |
            Should -Be ([Convert]::ToBase64String([System.IO.File]::ReadAllBytes($OriginalPath)))
    }

    function Get-PSWinUtilUtf8LfContent {
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

        $content = Get-PSWinUtilUtf8LfContent -Path $path
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

        $content = Get-PSWinUtilUtf8LfContent -Path $path
        $content | Should -Be "first`n$($script:UnicodeText)`n"
    }
}

Describe 'Out-File UTF-8 and LF default' -Skip:(-not $contentCommandOverridesAvailable) {
    It 'writes formatted text as UTF-8 without BOM and LF' {
        $path = Join-Path -Path $TestDrive -ChildPath 'out.txt'

        @($script:UnicodeText, 'second') | Out-File -LiteralPath $path

        $content = Get-PSWinUtilUtf8LfContent -Path $path
        $content | Should -Be "$($script:UnicodeText)`nsecond`n"
    }

    It 'appends to an existing Unicode file and converts it' {
        $path = Join-Path -Path $TestDrive -ChildPath 'out-append.txt'
        [System.IO.File]::WriteAllText($path, "first`r`n", [System.Text.Encoding]::Unicode)

        $script:UnicodeText | Out-File -LiteralPath $path -Append

        $content = Get-PSWinUtilUtf8LfContent -Path $path
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
    AfterEach {
        Enable-WUCommandOverride -Name $script:OverrideNames
    }

    It 'places every proxy when the module is imported' {
        foreach ($commandName in $script:OverrideNames) {
            (Get-Command -Name $commandName).ModuleName | Should -Be 'PSWinUtil'
        }
    }

    It 'resolves the original cmdlet for a disabled command' {
        Disable-WUCommandOverride -Name 'Get-Content'

        $command = Get-Command -Name 'Get-Content'
        $command.CommandType | Should -Be 'Cmdlet'
        $command.ModuleName | Should -Be 'Microsoft.PowerShell.Management'
    }

    It 'keeps every command that was not named' {
        Disable-WUCommandOverride -Name 'Get-Content'

        foreach ($commandName in @('Set-Content', 'Add-Content', 'Out-File')) {
            (Get-Command -Name $commandName).ModuleName | Should -Be 'PSWinUtil'
        }
    }

    It 'disables several commands at once' {
        Disable-WUCommandOverride -Name 'Get-Content', 'Set-Content', 'Add-Content', 'Out-File'

        foreach ($commandName in $script:OverrideNames) {
            (Get-Command -Name $commandName).CommandType | Should -Be 'Cmdlet'
        }
    }

    It 'places the proxy again after it was disabled' {
        Disable-WUCommandOverride -Name 'Set-Content'
        (Get-Command -Name 'Set-Content').CommandType | Should -Be 'Cmdlet'

        Enable-WUCommandOverride -Name 'Set-Content'
        (Get-Command -Name 'Set-Content').ModuleName | Should -Be 'PSWinUtil'

        $path = Join-Path -Path $TestDrive -ChildPath 'state-round-trip.txt'
        Set-Content -LiteralPath $path -Value @($script:UnicodeText, 'second')

        $content = Get-PSWinUtilUtf8LfContent -Path $path
        $content | Should -Be "$($script:UnicodeText)`nsecond`n"
    }

    It 'keeps the state when the same state is requested again' {
        Disable-WUCommandOverride -Name 'Out-File'
        { Disable-WUCommandOverride -Name 'Out-File' } | Should -Not -Throw
        (Get-Command -Name 'Out-File').CommandType | Should -Be 'Cmdlet'

        Enable-WUCommandOverride -Name 'Out-File'
        { Enable-WUCommandOverride -Name 'Out-File' } | Should -Not -Throw
        (Get-Command -Name 'Out-File').ModuleName | Should -Be 'PSWinUtil'
    }

    It 'keeps the proxy with WhatIf' {
        Disable-WUCommandOverride -Name 'Get-Content' -WhatIf

        (Get-Command -Name 'Get-Content').ModuleName | Should -Be 'PSWinUtil'
    }

    It 'rejects a command that PSWinUtil does not override' {
        { Disable-WUCommandOverride -Name 'Invoke-WebRequest' } | Should -Throw
        { Enable-WUCommandOverride -Name 'Get-ChildItem' } | Should -Throw
    }

    It 'reads with the original encoding default while the Get-Content override is disabled' {
        $path = Join-Path -Path $TestDrive -ChildPath 'state-get.txt'
        [System.IO.File]::WriteAllText($path, $script:UnicodeText, $script:Utf8NoBom)

        Disable-WUCommandOverride -Name 'Get-Content'
        Get-Content -LiteralPath $path -Raw |
            Should -Be (Microsoft.PowerShell.Management\Get-Content -LiteralPath $path -Raw)

        Enable-WUCommandOverride -Name 'Get-Content'
        Get-Content -LiteralPath $path -Raw | Should -Be $script:UnicodeText
    }

    It 'writes like the original cmdlet while the Set-Content override is disabled' {
        $proxyPath = Join-Path -Path $TestDrive -ChildPath 'state-set-proxy.txt'
        $originalPath = Join-Path -Path $TestDrive -ChildPath 'state-set-original.txt'

        Disable-WUCommandOverride -Name 'Set-Content'
        Set-Content -LiteralPath $proxyPath -Value @($script:UnicodeText, 'second')
        Microsoft.PowerShell.Management\Set-Content `
            -LiteralPath $originalPath `
            -Value @($script:UnicodeText, 'second')

        Assert-PSWinUtilFileByteEquality -ProxyPath $proxyPath -OriginalPath $originalPath
    }

    It 'appends like the original cmdlet while the Add-Content override is disabled' {
        $proxyPath = Join-Path -Path $TestDrive -ChildPath 'state-add-proxy.txt'
        $originalPath = Join-Path -Path $TestDrive -ChildPath 'state-add-original.txt'
        foreach ($path in @($proxyPath, $originalPath)) {
            [System.IO.File]::WriteAllText($path, "first`r`n", [System.Text.Encoding]::Unicode)
        }

        Disable-WUCommandOverride -Name 'Add-Content'
        Add-Content -LiteralPath $proxyPath -Value 'second'
        Microsoft.PowerShell.Management\Add-Content -LiteralPath $originalPath -Value 'second'

        Assert-PSWinUtilFileByteEquality -ProxyPath $proxyPath -OriginalPath $originalPath
    }

    It 'writes like the original cmdlet while the Out-File override is disabled' {
        $proxyPath = Join-Path -Path $TestDrive -ChildPath 'state-out-proxy.txt'
        $originalPath = Join-Path -Path $TestDrive -ChildPath 'state-out-original.txt'

        Disable-WUCommandOverride -Name 'Out-File'
        @($script:UnicodeText, 'second') | Out-File -LiteralPath $proxyPath
        @($script:UnicodeText, 'second') |
            Microsoft.PowerShell.Utility\Out-File -LiteralPath $originalPath

        Assert-PSWinUtilFileByteEquality -ProxyPath $proxyPath -OriginalPath $originalPath
    }
}
