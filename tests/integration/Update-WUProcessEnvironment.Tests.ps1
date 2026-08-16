Describe 'Process environment update integration' {
    BeforeAll {
        $repositoryRoot = Split-Path -Path (Split-Path -Path $PSScriptRoot -Parent) -Parent
        $manifestPath = Join-Path -Path $repositoryRoot -ChildPath 'output/PSWinUtil/PSWinUtil.psd1'
        Import-Module -Name $manifestPath -Force -ErrorAction Stop

        $script:ProcessTarget = [System.EnvironmentVariableTarget]::Process
        $script:UserTarget = [System.EnvironmentVariableTarget]::User
        $script:MachineTarget = [System.EnvironmentVariableTarget]::Machine
        $script:EnvironmentName = 'PSWINUTIL_UPDATE_' + [guid]::NewGuid().ToString('N')
        $script:OriginalProcessEnvironment = [System.Environment]::GetEnvironmentVariables(
            $script:ProcessTarget
        )
        $script:OriginalUserValue = [System.Environment]::GetEnvironmentVariable(
            $script:EnvironmentName,
            $script:UserTarget
        )
        $script:OriginalMachineValue = [System.Environment]::GetEnvironmentVariable(
            $script:EnvironmentName,
            $script:MachineTarget
        )
        $script:OriginalUserPath = [System.Environment]::GetEnvironmentVariable(
            'Path',
            $script:UserTarget
        )
        $script:OriginalMachinePath = [System.Environment]::GetEnvironmentVariable(
            'Path',
            $script:MachineTarget
        )
        $script:MachineTestPath = Join-Path -Path $TestDrive -ChildPath 'machine-path'
        $script:UserTestPath = Join-Path -Path $TestDrive -ChildPath 'user-path'
        $null = [System.IO.Directory]::CreateDirectory($script:MachineTestPath)
        $null = [System.IO.Directory]::CreateDirectory($script:UserTestPath)

        $script:RestoreEnvironment = {
            [System.Environment]::SetEnvironmentVariable(
                $script:EnvironmentName,
                $script:OriginalUserValue,
                $script:UserTarget
            )
            [System.Environment]::SetEnvironmentVariable(
                $script:EnvironmentName,
                $script:OriginalMachineValue,
                $script:MachineTarget
            )
            [System.Environment]::SetEnvironmentVariable(
                'Path',
                $script:OriginalUserPath,
                $script:UserTarget
            )
            [System.Environment]::SetEnvironmentVariable(
                'Path',
                $script:OriginalMachinePath,
                $script:MachineTarget
            )

            $currentProcessEnvironment = [System.Environment]::GetEnvironmentVariables(
                $script:ProcessTarget
            )
            foreach ($environmentName in $currentProcessEnvironment.Keys) {
                if (-not $script:OriginalProcessEnvironment.Contains($environmentName)) {
                    [System.Environment]::SetEnvironmentVariable(
                        [string]$environmentName,
                        $null,
                        $script:ProcessTarget
                    )
                }
            }
            foreach ($environmentName in $script:OriginalProcessEnvironment.Keys) {
                [System.Environment]::SetEnvironmentVariable(
                    [string]$environmentName,
                    [string]$script:OriginalProcessEnvironment[$environmentName],
                    $script:ProcessTarget
                )
            }
        }
    }

    BeforeEach {
        & $script:RestoreEnvironment
    }

    AfterEach {
        & $script:RestoreEnvironment
    }

    AfterAll {
        & $script:RestoreEnvironment
    }

    It 'copies a Machine variable to the current process' {
        [System.Environment]::SetEnvironmentVariable(
            $script:EnvironmentName,
            'machine value',
            $script:MachineTarget
        )
        [System.Environment]::SetEnvironmentVariable(
            $script:EnvironmentName,
            $null,
            $script:UserTarget
        )
        [System.Environment]::SetEnvironmentVariable(
            $script:EnvironmentName,
            'stale value',
            $script:ProcessTarget
        )

        Update-WUProcessEnvironment

        [System.Environment]::GetEnvironmentVariable(
            $script:EnvironmentName,
            $script:ProcessTarget
        ) | Should -Be 'machine value'
    }

    It 'uses a User variable instead of a Machine variable' {
        [System.Environment]::SetEnvironmentVariable(
            $script:EnvironmentName,
            'machine value',
            $script:MachineTarget
        )
        [System.Environment]::SetEnvironmentVariable(
            $script:EnvironmentName,
            'user value',
            $script:UserTarget
        )
        [System.Environment]::SetEnvironmentVariable(
            $script:EnvironmentName,
            'stale value',
            $script:ProcessTarget
        )

        Update-WUProcessEnvironment

        [System.Environment]::GetEnvironmentVariable(
            $script:EnvironmentName,
            $script:ProcessTarget
        ) | Should -Be 'user value'
    }

    It 'combines Machine and User PATH values in order' {
        $machinePathValues = @($script:MachineTestPath)
        if (-not [string]::IsNullOrEmpty($script:OriginalMachinePath)) {
            $machinePathValues = @($script:OriginalMachinePath, $script:MachineTestPath)
        }
        $userPathValues = @($script:UserTestPath)
        if (-not [string]::IsNullOrEmpty($script:OriginalUserPath)) {
            $userPathValues = @($script:OriginalUserPath, $script:UserTestPath)
        }
        [System.Environment]::SetEnvironmentVariable(
            'Path',
            $machinePathValues -join ';',
            $script:MachineTarget
        )
        [System.Environment]::SetEnvironmentVariable(
            'Path',
            $userPathValues -join ';',
            $script:UserTarget
        )
        [System.Environment]::SetEnvironmentVariable(
            'Path',
            'C:\Stale',
            $script:ProcessTarget
        )

        Update-WUProcessEnvironment

        $processPath = [System.Environment]::GetEnvironmentVariable('Path', $script:ProcessTarget)
        $processPathItems = @($processPath -split ';')
        $machinePathIndex = [System.Array]::IndexOf($processPathItems, $script:MachineTestPath)
        $userPathIndex = [System.Array]::IndexOf($processPathItems, $script:UserTestPath)
        $machinePathIndex | Should -BeGreaterOrEqual 0
        $userPathIndex | Should -BeGreaterThan $machinePathIndex
    }

    It 'does not update the current process with WhatIf' {
        [System.Environment]::SetEnvironmentVariable(
            $script:EnvironmentName,
            'user value',
            $script:UserTarget
        )
        [System.Environment]::SetEnvironmentVariable(
            $script:EnvironmentName,
            'stale value',
            $script:ProcessTarget
        )

        Update-WUProcessEnvironment -WhatIf

        [System.Environment]::GetEnvironmentVariable(
            $script:EnvironmentName,
            $script:ProcessTarget
        ) | Should -Be 'stale value'
    }
}
