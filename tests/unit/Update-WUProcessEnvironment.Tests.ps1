BeforeAll {
    . (Join-Path -Path $PSScriptRoot -ChildPath '../UnitTestBootstrap.ps1')

    $script:EnvironmentTarget = [System.EnvironmentVariableTarget]::Process
}

Describe 'Update-WUProcessEnvironment' {
    BeforeEach {
        $script:OriginalProcessEnvironment = [Environment]::GetEnvironmentVariables('Process')
    }

    AfterEach {
        foreach ($name in [Environment]::GetEnvironmentVariables('Process').Keys) {
            if (-not $script:OriginalProcessEnvironment.Contains($name)) {
                [Environment]::SetEnvironmentVariable($name, $null, 'Process')
            }
        }
        foreach ($name in $script:OriginalProcessEnvironment.Keys) {
            [Environment]::SetEnvironmentVariable($name, $script:OriginalProcessEnvironment[$name], 'Process')
        }
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
