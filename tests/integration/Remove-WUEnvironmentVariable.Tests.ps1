BeforeAll {
    . (Join-Path -Path $PSScriptRoot -ChildPath '../UnitTestBootstrap.ps1')
}

Describe 'Remove-WUEnvironmentVariable' {
    BeforeEach {
        $script:VariableName = 'PSWINUTIL_REMOVE_' + [guid]::NewGuid().ToString('N')
        $script:OtherVariableName = 'PSWINUTIL_KEEP_' + [guid]::NewGuid().ToString('N')
        [Environment]::SetEnvironmentVariable($script:VariableName, 'remove me', 'Process')
        [Environment]::SetEnvironmentVariable($script:OtherVariableName, 'keep me', 'Process')
    }

    AfterEach {
        [Environment]::SetEnvironmentVariable($script:VariableName, $null, 'Process')
        [Environment]::SetEnvironmentVariable($script:OtherVariableName, $null, 'Process')
    }

    It 'removes a variable from the selected environment' {
        Remove-WUEnvironmentVariable -Name $script:VariableName -Scope Process

        [Environment]::GetEnvironmentVariable($script:VariableName, 'Process') | Should -BeNullOrEmpty
    }

    It 'succeeds when the variable is already absent' {
        [Environment]::SetEnvironmentVariable($script:VariableName, $null, 'Process')

        { Remove-WUEnvironmentVariable -Name $script:VariableName -Scope Process } | Should -Not -Throw
        [Environment]::GetEnvironmentVariable($script:VariableName, 'Process') | Should -BeNullOrEmpty
    }

    It 'preserves unrelated environment variables' {
        Remove-WUEnvironmentVariable -Name $script:VariableName -Scope Process

        [Environment]::GetEnvironmentVariable($script:OtherVariableName, 'Process') | Should -Be 'keep me'
    }

    It 'preserves the variable when previewing removal' {
        Remove-WUEnvironmentVariable -Name $script:VariableName -Scope Process -WhatIf

        [Environment]::GetEnvironmentVariable($script:VariableName, 'Process') | Should -Be 'remove me'
        [Environment]::GetEnvironmentVariable($script:OtherVariableName, 'Process') | Should -Be 'keep me'
    }
}
