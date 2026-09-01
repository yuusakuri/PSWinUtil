BeforeAll {
    . (Join-Path -Path $PSScriptRoot -ChildPath '../UnitTestBootstrap.ps1')
}

Describe 'Remove-WUEnvironmentVariable' {
    BeforeEach {
        Mock -CommandName Set-WUEnvironmentVariable -ModuleName PSWinUtil -MockWith {}
    }

    It 'delegates removal to Set-WUEnvironmentVariable' {
        Remove-WUEnvironmentVariable -Name 'PSWINUTIL_TEST_NAME' -Scope Machine

        Should -Invoke -CommandName Set-WUEnvironmentVariable -ModuleName PSWinUtil -Times 1 -Exactly -ParameterFilter {
            $Name -eq 'PSWINUTIL_TEST_NAME' -and
            $null -eq $Value -and
            $Scope -eq 'Machine'
        }
    }

    It 'delegates removal even when the variable does not exist' {
        Remove-WUEnvironmentVariable -Name 'PSWINUTIL_MISSING_NAME' -Scope User

        Should -Invoke -CommandName Set-WUEnvironmentVariable -ModuleName PSWinUtil -Times 1 -Exactly -ParameterFilter {
            $Name -eq 'PSWINUTIL_MISSING_NAME' -and
            $null -eq $Value -and
            $Scope -eq 'User'
        }
    }

    It 'delegates every selected scope' {
        Remove-WUEnvironmentVariable `
            -Name 'PSWINUTIL_TEST_NAME' `
            -Scope Process, User

        Should -Invoke -CommandName Set-WUEnvironmentVariable -ModuleName PSWinUtil -Times 1 -Exactly -ParameterFilter {
            @($Scope).Count -eq 2 -and
            $Scope[0] -eq 'Process' -and
            $Scope[1] -eq 'User'
        }
    }

    It 'forwards WhatIf to Set-WUEnvironmentVariable' {
        Remove-WUEnvironmentVariable -Name 'PSWINUTIL_TEST_NAME' -WhatIf

        Should -Invoke -CommandName Set-WUEnvironmentVariable -ModuleName PSWinUtil -Times 1 -Exactly -ParameterFilter {
            $WhatIf
        }
    }

    It 'forwards Confirm to Set-WUEnvironmentVariable' {
        Remove-WUEnvironmentVariable -Name 'PSWINUTIL_TEST_NAME' -Confirm:$false

        Should -Invoke -CommandName Set-WUEnvironmentVariable -ModuleName PSWinUtil -Times 1 -Exactly -ParameterFilter {
            -not $Confirm
        }
    }
}
