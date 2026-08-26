BeforeAll {
    $repositoryRoot = Split-Path -Path (Split-Path -Path $PSScriptRoot -Parent) -Parent
    $manifestPath = Join-Path -Path $repositoryRoot -ChildPath 'output/PSWinUtil/PSWinUtil.psd1'
    Import-Module -Name $manifestPath -Force -ErrorAction Stop

    $script:EnvironmentTarget = [System.EnvironmentVariableTarget]::Process
    $script:UserEnvironmentTarget = [System.EnvironmentVariableTarget]::User
    $script:FileEnvironmentName = 'PSWINUTIL_FILE_TEST_NAME'
}

Describe 'Set-WUEnvironmentVariable' {
    BeforeEach {
        $script:EnvironmentName = 'PSWINUTIL_UNIT_' + [guid]::NewGuid().ToString('N')
        $script:OriginalFileValue = [System.Environment]::GetEnvironmentVariable(
            $script:FileEnvironmentName,
            $script:EnvironmentTarget
        )

        Mock -CommandName Import-WUEnvironmentVariableSetting -ModuleName PSWinUtil -MockWith {
            [pscustomobject]@{
                Name = 'PSWINUTIL_FILE_TEST_NAME'
                Value = 'file value'
                Scope = 'Process'
            }
        }
    }

    AfterEach {
        [System.Environment]::SetEnvironmentVariable(
            $script:EnvironmentName,
            $null,
            $script:EnvironmentTarget
        )
        [System.Environment]::SetEnvironmentVariable(
            $script:EnvironmentName,
            $null,
            $script:UserEnvironmentTarget
        )
        [System.Environment]::SetEnvironmentVariable(
            $script:FileEnvironmentName,
            $script:OriginalFileValue,
            $script:EnvironmentTarget
        )
    }

    It 'sets a named variable in the selected scope' {
        Set-WUEnvironmentVariable -Name $script:EnvironmentName -Value 'value' -Scope Process

        [System.Environment]::GetEnvironmentVariable(
            $script:EnvironmentName,
            $script:EnvironmentTarget
        ) | Should -Be 'value'
    }

    It 'loads file settings through the private importer' {
        Set-WUEnvironmentVariable -Path '.\environment.psd1' -Scope Process

        Should -Invoke -CommandName Import-WUEnvironmentVariableSetting -ModuleName PSWinUtil -Times 1 -Exactly -ParameterFilter {
            $Path -contains '.\environment.psd1' -and $Scope -eq 'Process'
        }
        [System.Environment]::GetEnvironmentVariable(
            $script:FileEnvironmentName,
            $script:EnvironmentTarget
        ) | Should -Be 'file value'
    }

    It 'forwards LiteralPath to the private importer' {
        Set-WUEnvironmentVariable -LiteralPath '.\environment[1].psd1' -Scope Process

        Should -Invoke -CommandName Import-WUEnvironmentVariableSetting -ModuleName PSWinUtil -Times 1 -Exactly -ParameterFilter {
            $LiteralPath -contains '.\environment[1].psd1' -and
            $null -eq $Path -and
            $Scope -eq 'Process'
        }
    }

    It 'sets a named variable in multiple scopes' -Skip:($env:OS -ne 'Windows_NT') {
        $result = @(
            Set-WUEnvironmentVariable `
                -Name $script:EnvironmentName `
                -Value 'shared value' `
                -Scope Process, User `
                -PassThru
        )

        $result | Should -HaveCount 2
        $result.Scope | Should -Contain 'Process'
        $result.Scope | Should -Contain 'User'
        [System.Environment]::GetEnvironmentVariable(
            $script:EnvironmentName,
            $script:EnvironmentTarget
        ) | Should -Be 'shared value'
        [System.Environment]::GetEnvironmentVariable(
            $script:EnvironmentName,
            $script:UserEnvironmentTarget
        ) | Should -Be 'shared value'
    }

    It 'does not set a variable with WhatIf' {
        Set-WUEnvironmentVariable -Name $script:EnvironmentName -Value 'value' -WhatIf

        [System.Environment]::GetEnvironmentVariable(
            $script:EnvironmentName,
            $script:EnvironmentTarget
        ) | Should -BeNullOrEmpty
    }

    It 'removes a variable when the value is null' {
        [System.Environment]::SetEnvironmentVariable(
            $script:EnvironmentName,
            'value to remove',
            $script:EnvironmentTarget
        )

        Set-WUEnvironmentVariable -Name $script:EnvironmentName -Value $null -Scope Process

        [System.Environment]::GetEnvironmentVariable(
            $script:EnvironmentName,
            $script:EnvironmentTarget
        ) | Should -BeNullOrEmpty
    }

    It 'returns the stored state only with PassThru' {
        $result = Set-WUEnvironmentVariable `
            -Name $script:EnvironmentName `
            -Value 'stored value' `
            -Scope Process `
            -PassThru

        $result.Name | Should -Be $script:EnvironmentName
        $result.Value | Should -Be 'stored value'
        $result.Scope | Should -Be 'Process'
    }

    It 'does not return the stored state without PassThru' {
        $result = Set-WUEnvironmentVariable -Name $script:EnvironmentName -Value 'value'

        $result | Should -BeNullOrEmpty
    }

    It 'rejects an invalid environment variable name' {
        {
            Set-WUEnvironmentVariable -Name 'INVALID=NAME' -Value 'value'
        } | Should -Throw
    }

    It 'rejects a non-string environment variable value' {
        {
            Set-WUEnvironmentVariable -Name $script:EnvironmentName -Value 1
        } | Should -Throw
    }
}
