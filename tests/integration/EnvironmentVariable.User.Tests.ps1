Describe 'User environment variable integration' {
    BeforeAll {
        $repositoryRoot = Split-Path -Path (Split-Path -Path $PSScriptRoot -Parent) -Parent
        $manifestPath = Join-Path -Path $repositoryRoot -ChildPath 'output/PSWinUtil/PSWinUtil.psd1'
        Import-Module -Name $manifestPath -Force -ErrorAction Stop

        $script:EnvironmentTarget = [System.EnvironmentVariableTarget]::User
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

    It 'sets a User environment variable' {
        Set-WUEnvironmentVariable -Name $script:EnvironmentName -Value 'user value' -Scope User

        [System.Environment]::GetEnvironmentVariable(
            $script:EnvironmentName,
            $script:EnvironmentTarget
        ) | Should -Be 'user value'
    }

    It 'gets a User environment variable' {
        [System.Environment]::SetEnvironmentVariable(
            $script:EnvironmentName,
            'user value',
            $script:EnvironmentTarget
        )

        Get-WUEnvironmentVariable -Name $script:EnvironmentName -Scope User |
            Should -Be 'user value'
    }

    It 'removes a User environment variable' {
        [System.Environment]::SetEnvironmentVariable(
            $script:EnvironmentName,
            'value to remove',
            $script:EnvironmentTarget
        )

        Remove-WUEnvironmentVariable -Name $script:EnvironmentName -Scope User

        $actualValue = [System.Environment]::GetEnvironmentVariable(
            $script:EnvironmentName,
            $script:EnvironmentTarget
        )
        ($null -eq $actualValue) | Should -BeTrue
    }

    It 'removes a User environment variable with a null value' {
        [System.Environment]::SetEnvironmentVariable(
            $script:EnvironmentName,
            'value to remove',
            $script:EnvironmentTarget
        )

        Set-WUEnvironmentVariable -Name $script:EnvironmentName -Value $null -Scope User

        $actualValue = [System.Environment]::GetEnvironmentVariable(
            $script:EnvironmentName,
            $script:EnvironmentTarget
        )
        ($null -eq $actualValue) | Should -BeTrue
    }
}
