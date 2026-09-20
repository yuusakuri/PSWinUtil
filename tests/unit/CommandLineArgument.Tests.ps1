BeforeAll {
    . (Join-Path -Path $PSScriptRoot -ChildPath '../UnitTestBootstrap.ps1')
}

Describe 'ConvertTo-WUCommandLineArgument' {
    It 'preserves an argument that does not require quotes' {
        ConvertTo-WUCommandLineArgument -Argument 'alpha-beta' | Should -BeExactly 'alpha-beta'
    }

    It 'represents an empty argument' {
        ConvertTo-WUCommandLineArgument -Argument '' | Should -BeExactly '""'
    }

    It 'quotes spaces and trailing backslashes' {
        ConvertTo-WUCommandLineArgument -Argument 'C:\Program Files\' |
            Should -BeExactly '"C:\Program Files\\"'
    }

    It 'escapes a quotation mark inside an argument' {
        ConvertTo-WUCommandLineArgument -Argument 'say "hello"' |
            Should -BeExactly '"say \"hello\""'
    }

    It 'quotes an argument when requested' {
        ConvertTo-WUCommandLineArgument -Argument 'simple' -AlwaysQuote |
            Should -BeExactly '"simple"'
    }

    It 'rejects a null character' {
        { ConvertTo-WUCommandLineArgument -Argument ("before$([char]0)after") } |
            Should -Throw '*null character*'
    }
}
