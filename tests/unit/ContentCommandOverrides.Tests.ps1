BeforeAll {
    $repositoryRoot = Split-Path -Path (Split-Path -Path $PSScriptRoot -Parent) -Parent
    $manifestPath = Join-Path -Path $repositoryRoot -ChildPath 'output/PSWinUtil/PSWinUtil.psd1'
    Import-Module -Name $manifestPath -Force -ErrorAction Stop

    $script:Utf8NoBom = [System.Text.UTF8Encoding]::new($false)
    $script:UnicodeText = [string][char]0x3042
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

Describe 'Content command precedence' {
    It 'uses the PSWinUtil functions before the built-in cmdlets' {
        foreach ($commandName in @('Get-Content', 'Set-Content', 'Add-Content', 'Out-File')) {
            $selectedCommand = Get-Command -Name $commandName
            $selectedCommand.CommandType | Should -Be 'Function'
            $selectedCommand.ModuleName | Should -Be 'PSWinUtil'
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

Describe 'Get-Content UTF-8 default' {
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

Describe 'Set-Content UTF-8 and LF default' {
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

Describe 'Add-Content UTF-8 and LF default' {
    It 'converts existing Unicode content and appends UTF-8 with LF' {
        $path = Join-Path -Path $TestDrive -ChildPath 'add.txt'
        [System.IO.File]::WriteAllText($path, "first`r`n", [System.Text.Encoding]::Unicode)

        Add-Content -LiteralPath $path -Value $script:UnicodeText

        $content = & $script:AssertUtf8Lf -Path $path
        $content | Should -Be "first`n$($script:UnicodeText)`n"
    }
}

Describe 'Out-File UTF-8 and LF default' {
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
