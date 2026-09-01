BeforeAll {
    . (Join-Path -Path $PSScriptRoot -ChildPath '../UnitTestBootstrap.ps1')

    $script:EnvironmentTarget = [System.EnvironmentVariableTarget]::Process
    $script:UserEnvironmentTarget = [System.EnvironmentVariableTarget]::User
}

Describe 'Get-WUEnvironmentVariable' {
    BeforeEach {
        $script:FirstEnvironmentName = 'PSWINUTIL_GET_' + [guid]::NewGuid().ToString('N')
        $script:SecondEnvironmentName = 'PSWINUTIL_GET_' + [guid]::NewGuid().ToString('N')
    }

    AfterEach {
        [System.Environment]::SetEnvironmentVariable(
            $script:FirstEnvironmentName,
            $null,
            $script:EnvironmentTarget
        )
        [System.Environment]::SetEnvironmentVariable(
            $script:SecondEnvironmentName,
            $null,
            $script:EnvironmentTarget
        )
        [System.Environment]::SetEnvironmentVariable(
            $script:FirstEnvironmentName,
            $null,
            $script:UserEnvironmentTarget
        )
        [System.Environment]::SetEnvironmentVariable(
            $script:SecondEnvironmentName,
            $null,
            $script:UserEnvironmentTarget
        )
    }

    It 'gets a variable from the selected scope' {
        [System.Environment]::SetEnvironmentVariable(
            $script:FirstEnvironmentName,
            'first value',
            $script:EnvironmentTarget
        )

        Get-WUEnvironmentVariable -Name $script:FirstEnvironmentName -Scope Process |
            Should -Be 'first value'
    }

    It 'gets multiple variables from the pipeline' {
        [System.Environment]::SetEnvironmentVariable(
            $script:FirstEnvironmentName,
            'first value',
            $script:EnvironmentTarget
        )
        [System.Environment]::SetEnvironmentVariable(
            $script:SecondEnvironmentName,
            'second value',
            $script:EnvironmentTarget
        )

        $result = @(
            $script:FirstEnvironmentName, $script:SecondEnvironmentName |
                Get-WUEnvironmentVariable -Scope Process
        )

        $result.Count | Should -Be 2
        $result[0] | Should -Be 'first value'
        $result[1] | Should -Be 'second value'
    }

    It 'gets a variable from multiple scopes in the specified order' -Skip:($env:OS -ne 'Windows_NT') {
        [System.Environment]::SetEnvironmentVariable(
            $script:FirstEnvironmentName,
            'process value',
            $script:EnvironmentTarget
        )
        [System.Environment]::SetEnvironmentVariable(
            $script:FirstEnvironmentName,
            'user value',
            $script:UserEnvironmentTarget
        )

        $result = @(
            Get-WUEnvironmentVariable `
                -Name $script:FirstEnvironmentName `
                -Scope Process, User
        )

        $result | Should -HaveCount 2
        $result[0] | Should -Be 'process value'
        $result[1] | Should -Be 'user value'
    }

    It 'returns no value when the variable does not exist' {
        $result = Get-WUEnvironmentVariable -Name $script:FirstEnvironmentName -Scope Process

        $result | Should -BeNullOrEmpty
    }

    It 'rejects an invalid environment variable name' {
        {
            Get-WUEnvironmentVariable -Name 'INVALID=NAME'
        } | Should -Throw
    }
}
