Describe 'Process environment variable integration' {
    BeforeAll {
        $repositoryRoot = Split-Path -Path (Split-Path -Path $PSScriptRoot -Parent) -Parent
        $manifestPath = Join-Path -Path $repositoryRoot -ChildPath 'output/PSWinUtil/PSWinUtil.psd1'
        Import-Module -Name $manifestPath -Force -ErrorAction Stop

        $script:EnvironmentTarget = [System.EnvironmentVariableTarget]::Process
        $script:EnvironmentName = 'PSWINUTIL_TEST_' + [guid]::NewGuid().ToString('N')
        $script:OriginalValue = [System.Environment]::GetEnvironmentVariable(
            $script:EnvironmentName,
            $script:EnvironmentTarget
        )
    }

    BeforeEach {
        [System.Environment]::SetEnvironmentVariable(
            $script:EnvironmentName,
            $script:OriginalValue,
            $script:EnvironmentTarget
        )
    }

    AfterEach {
        [System.Environment]::SetEnvironmentVariable(
            $script:EnvironmentName,
            $script:OriginalValue,
            $script:EnvironmentTarget
        )
    }

    AfterAll {
        [System.Environment]::SetEnvironmentVariable(
            $script:EnvironmentName,
            $script:OriginalValue,
            $script:EnvironmentTarget
        )
    }

    It 'sets a Process environment variable' {
        Set-WUEnvironmentVariable -Name $script:EnvironmentName -Value 'process value' -Scope Process

        [System.Environment]::GetEnvironmentVariable(
            $script:EnvironmentName,
            $script:EnvironmentTarget
        ) | Should -Be 'process value'
    }

    It 'gets a Process environment variable' {
        [System.Environment]::SetEnvironmentVariable(
            $script:EnvironmentName,
            'process value',
            $script:EnvironmentTarget
        )

        Get-WUEnvironmentVariable -Name $script:EnvironmentName -Scope Process |
            Should -Be 'process value'
    }

    It 'removes a Process environment variable' {
        [System.Environment]::SetEnvironmentVariable(
            $script:EnvironmentName,
            'value to remove',
            $script:EnvironmentTarget
        )

        Remove-WUEnvironmentVariable -Name $script:EnvironmentName -Scope Process

        $actualValue = [System.Environment]::GetEnvironmentVariable(
            $script:EnvironmentName,
            $script:EnvironmentTarget
        )
        ($null -eq $actualValue) | Should -BeTrue
    }

    It 'removes a Process environment variable with a null value' {
        [System.Environment]::SetEnvironmentVariable(
            $script:EnvironmentName,
            'value to remove',
            $script:EnvironmentTarget
        )

        Set-WUEnvironmentVariable -Name $script:EnvironmentName -Value $null -Scope Process

        $actualValue = [System.Environment]::GetEnvironmentVariable(
            $script:EnvironmentName,
            $script:EnvironmentTarget
        )
        ($null -eq $actualValue) | Should -BeTrue
    }
}
