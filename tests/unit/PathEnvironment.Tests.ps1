BeforeAll {
    . (Join-Path -Path $PSScriptRoot -ChildPath '../UnitTestBootstrap.ps1')
}

Describe 'Compare-WUPath' {
    It 'normalizes Windows path spelling without changing the input' {
        Compare-WUPath -ReferencePath 'C:\Tools\bin' -DifferencePath 'c:/Tools/.\bin\' |
            Should -BeTrue
    }

    It 'does not use process-only variables for persistent scopes' {
        $name = 'PSWINUTIL_COMPARE_' + [guid]::NewGuid().ToString('N')
        [Environment]::SetEnvironmentVariable($name, 'C:\Tools', 'Process')
        try {
            Compare-WUPath `
                -ReferencePath "%$name%\bin" `
                -DifferencePath 'C:\Tools\bin' `
                -Scope User |
                Should -BeFalse
        } finally {
            [Environment]::SetEnvironmentVariable($name, $null, 'Process')
        }
    }

    It 'does not make an unresolved variable relative to the current directory' {
        Compare-WUPath `
            -ReferencePath '%PSWINUTIL_UNKNOWN%\bin' `
            -DifferencePath (Join-Path (Get-Location) '%PSWINUTIL_UNKNOWN%\bin') `
            -Scope Process |
            Should -BeFalse
    }
}
