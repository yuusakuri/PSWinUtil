BeforeAll {
    $repositoryRoot = Split-Path -Path (Split-Path -Path $PSScriptRoot -Parent) -Parent
    $manifestPath = Join-Path -Path $repositoryRoot -ChildPath 'output/PSWinUtil/PSWinUtil.psd1'
    Import-Module -Name $manifestPath -Force -ErrorAction Stop

    $script:AssertUtf8LfFile = {
        param([string]$Path)

        [byte[]]$bytes = [System.IO.File]::ReadAllBytes($Path)
        if ($bytes.Length -ge 3) {
            $bytes[0..2] | Should -Not -Be @(0xEF, 0xBB, 0xBF)
        }
        $bytes | Should -Not -Contain 0x0D
    }
}

$contentCommandOverridesAvailable = $PSVersionTable.PSEdition -eq 'Desktop'

Describe 'Content command override integration' -Skip:(-not $contentCommandOverridesAvailable) {
    It 'uses the proxy for unqualified content commands' {
        foreach ($commandName in @('Get-Content', 'Set-Content', 'Add-Content', 'Out-File')) {
            (Get-Command -Name $commandName).ModuleName | Should -Be 'PSWinUtil'
        }
    }

    It 'writes UTF-8 without BOM and LF through every write command' {
        $setPath = Join-Path -Path $TestDrive -ChildPath 'set.txt'
        $addPath = Join-Path -Path $TestDrive -ChildPath 'add.txt'
        $outPath = Join-Path -Path $TestDrive -ChildPath 'out.txt'

        Set-Content -LiteralPath $setPath -Value @('first', 'second')
        Set-Content -LiteralPath $addPath -Value 'first'
        Add-Content -LiteralPath $addPath -Value 'second'
        @('first', 'second') | Out-File -LiteralPath $outPath

        foreach ($path in @($setPath, $addPath, $outPath)) {
            & $script:AssertUtf8LfFile -Path $path
        }
    }
}
