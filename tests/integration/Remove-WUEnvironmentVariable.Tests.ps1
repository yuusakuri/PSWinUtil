BeforeAll {
    . (Join-Path -Path $PSScriptRoot -ChildPath '../UnitTestBootstrap.ps1')
}

Describe 'Remove-WUEnvironmentVariable' {
    BeforeEach {
        $script:Names = @(
            'PSWINUTIL_REMOVE_' + [guid]::NewGuid().ToString('N')
            'PSWINUTIL_REMOVE_' + [guid]::NewGuid().ToString('N')
        )
        foreach ($name in $script:Names) {
            [Environment]::SetEnvironmentVariable($name, 'value to remove', 'Process')
        }
    }

    AfterEach {
        foreach ($name in $script:Names) {
            [Environment]::SetEnvironmentVariable($name, $null, 'Process')
        }
    }

    It 'removes all names supplied by <InputKind>' -ForEach @(
        @{ InputKind = 'array' }
        @{ InputKind = 'pipeline' }
        @{ InputKind = 'property pipeline' }
    ) {
        switch ($InputKind) {
            'array' { Remove-WUEnvironmentVariable -Name $script:Names }
            'pipeline' { $script:Names | Remove-WUEnvironmentVariable }
            'property pipeline' {
                $script:Names | ForEach-Object { [pscustomobject]@{ Name = $_ } } | Remove-WUEnvironmentVariable
            }
        }
        foreach ($name in $script:Names) {
            [Environment]::GetEnvironmentVariable($name, 'Process') | Should -BeNullOrEmpty
        }
    }

    It 'previews removal of all names without deleting their values' {
        $script:Names | Remove-WUEnvironmentVariable -WhatIf
        foreach ($name in $script:Names) {
            [Environment]::GetEnvironmentVariable($name, 'Process') | Should -Be 'value to remove'
        }
    }

    It 'accepts an empty pipeline without removing a value' {
        @() | Remove-WUEnvironmentVariable
        foreach ($name in $script:Names) {
            [Environment]::GetEnvironmentVariable($name, 'Process') | Should -Be 'value to remove'
        }
    }
}
