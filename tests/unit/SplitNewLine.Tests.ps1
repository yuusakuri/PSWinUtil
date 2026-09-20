BeforeAll {
    . (Join-Path -Path $PSScriptRoot -ChildPath '../UnitTestBootstrap.ps1')
}

Describe 'Split-WUNewLine' {
    It 'splits both Windows and Unix command output from the pipeline' {
        $lines = @("first`r`nsecond", "third`nfourth") | Split-WUNewLine

        $lines | Should -Be @('first', 'second', 'third', 'fourth')
    }

    It 'preserves blank lines and the final empty line' {
        $lines = @(Split-WUNewLine -InputObject "first`n`n")

        $lines | Should -Be @('first', '', '')
    }
}
