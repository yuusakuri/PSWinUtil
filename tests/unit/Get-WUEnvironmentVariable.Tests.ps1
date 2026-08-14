BeforeAll {
    $repositoryRoot = Split-Path -Path (Split-Path -Path $PSScriptRoot -Parent) -Parent
    $manifestPath = Join-Path -Path $repositoryRoot -ChildPath 'output/PSWinUtil/PSWinUtil.psd1'
    Import-Module -Name $manifestPath -Force -ErrorAction Stop

    $script:EnvironmentTarget = [System.EnvironmentVariableTarget]::Process
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
