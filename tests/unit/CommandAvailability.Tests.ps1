BeforeAll {
    . (Join-Path -Path $PSScriptRoot -ChildPath '../UnitTestBootstrap.ps1')
}

Describe 'Command availability helpers' {
    It 'returns true only for an available command' {
        Test-WUCommand -Name 'Write-Output' | Should -BeTrue
        Test-WUCommand -Name 'PSWinUtil-command-that-does-not-exist' | Should -BeFalse
    }

    It 'returns one result for each command name' {
        Test-WUCommand -Name 'Write-Output', 'PSWinUtil-command-that-does-not-exist' |
            Should -Be @($true, $false)
    }

    It 'asserts an available command and reports a missing command' {
        { Assert-WUCommand -Name 'Write-Output' } | Should -Not -Throw
        { Assert-WUCommand -Name 'PSWinUtil-command-that-does-not-exist' } |
            Should -Throw "Command 'PSWinUtil-command-that-does-not-exist' is not available."
    }

    It 'asserts multiple available commands' {
        { Assert-WUCommand -Name @('Write-Output', 'Write-Error') } | Should -Not -Throw
    }
}
