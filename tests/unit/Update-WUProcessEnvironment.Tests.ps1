BeforeAll {
    . (Join-Path -Path $PSScriptRoot -ChildPath '../UnitTestBootstrap.ps1')

    $script:EnvironmentTarget = [System.EnvironmentVariableTarget]::Process
}

Describe 'Update-WUProcessEnvironment' {
    BeforeEach {
        $script:OriginalPathValue = [System.Environment]::GetEnvironmentVariable(
            'Path',
            $script:EnvironmentTarget
        )
    }

    AfterEach {
        [System.Environment]::SetEnvironmentVariable(
            'Path',
            $script:OriginalPathValue,
            $script:EnvironmentTarget
        )
    }

    It 'supports WhatIf and Confirm' {
        $command = Get-Command -Name 'Update-WUProcessEnvironment' -Module 'PSWinUtil'

        $command.Parameters.ContainsKey('WhatIf') | Should -BeTrue
        $command.Parameters.ContainsKey('Confirm') | Should -BeTrue
    }

    It 'does not update the current process with WhatIf' {
        [System.Environment]::SetEnvironmentVariable(
            'Path',
            'PSWINUTIL_WHATIF_PATH',
            $script:EnvironmentTarget
        )

        Update-WUProcessEnvironment -WhatIf

        [System.Environment]::GetEnvironmentVariable(
            'Path',
            $script:EnvironmentTarget
        ) | Should -Be 'PSWINUTIL_WHATIF_PATH'
    }

    It 'does not expand process-only variables in persistent paths' {
        $variableName = 'PSWINUTIL_PROCESS_ONLY'
        $originalValue = [Environment]::GetEnvironmentVariable($variableName, $script:EnvironmentTarget)
        $originalPath = [Environment]::GetEnvironmentVariable('Path', $script:EnvironmentTarget)
        [Environment]::SetEnvironmentVariable($variableName, 'C:\ProcessOnly', $script:EnvironmentTarget)
        Mock -CommandName Get-WUEnvironmentVariable -ModuleName PSWinUtil -MockWith {
            if ($Scope -contains 'Machine') {
                return ''
            }

            "%$variableName%\bin"
        }

        try {
            Update-WUProcessEnvironment

            [Environment]::GetEnvironmentVariable('Path', $script:EnvironmentTarget) |
                Should -Match ([regex]::Escape("%$variableName%\bin"))
            [Environment]::GetEnvironmentVariable('Path', $script:EnvironmentTarget) |
                Should -Not -Match ([regex]::Escape("C:\ProcessOnly\bin"))
        } finally {
            [Environment]::SetEnvironmentVariable('Path', $originalPath, $script:EnvironmentTarget)
            [Environment]::SetEnvironmentVariable($variableName, $originalValue, $script:EnvironmentTarget)
        }
    }
}
