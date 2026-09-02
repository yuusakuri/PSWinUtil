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
}
