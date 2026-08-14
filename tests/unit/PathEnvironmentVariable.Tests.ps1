BeforeAll {
    $repositoryRoot = Split-Path -Path (Split-Path -Path $PSScriptRoot -Parent) -Parent
    $manifestPath = Join-Path -Path $repositoryRoot -ChildPath 'output/PSWinUtil/PSWinUtil.psd1'
    Import-Module -Name $manifestPath -Force -ErrorAction Stop
}

Describe 'PATH value helpers' {
    InModuleScope -ModuleName PSWinUtil {
        It 'splits, trims, and removes empty items' {
            $pathItems = @(
                Split-WUPathEnvironmentVariable -Value ' ; C:\One ; ; C:\Two\ ; '
            )

            $pathItems.Count | Should -Be 2
            $pathItems[0] | Should -Be 'C:\One'
            $pathItems[1] | Should -Be 'C:\Two\'
        }

        It 'joins items with semicolons' {
            Join-WUPathEnvironmentVariable -Path 'C:\One', 'C:\Two' |
                Should -Be 'C:\One;C:\Two'
        }

        It 'joins an empty collection as an empty string' {
            [string]$joinedValue = Join-WUPathEnvironmentVariable -Path @()

            $joinedValue | Should -Be ''
        }

        It 'compares paths without case or a trailing backslash' {
            Compare-WUPath -ReferencePath ' C:\Tools ' -DifferencePath 'c:\tools\' |
                Should -BeTrue
        }

        It 'does not treat a drive-relative path as a drive root' {
            Compare-WUPath -ReferencePath 'C:\' -DifferencePath 'C:' |
                Should -BeFalse
        }
    }
}

Describe 'Add-WUPathEnvironmentVariable' {
    BeforeEach {
        Mock -CommandName Get-WUEnvironmentVariableValue -ModuleName PSWinUtil -MockWith {
            'C:\One;C:\Two\'
        }
        Mock -CommandName Set-WUEnvironmentVariableValue -ModuleName PSWinUtil -MockWith {}
    }

    It 'appends new paths and ignores normalized duplicates' {
        Add-WUPathEnvironmentVariable -Path 'c:\one\', 'C:\Three', 'c:\three\' -Scope User

        Should -Invoke -CommandName Set-WUEnvironmentVariableValue -ModuleName PSWinUtil -Times 1 -Exactly -ParameterFilter {
            $Name -eq 'Path' -and
            $Value -eq 'C:\One;C:\Two\;C:\Three' -and
            $Scope -eq 'User'
        }
    }

    It 'prepends new paths in input order' {
        Add-WUPathEnvironmentVariable -Path 'C:\Three', 'C:\Four' -Scope Process -Prepend

        Should -Invoke -CommandName Set-WUEnvironmentVariableValue -ModuleName PSWinUtil -Times 1 -Exactly -ParameterFilter {
            $Value -eq 'C:\Three;C:\Four;C:\One;C:\Two\'
        }
    }

    It 'does nothing when every path already exists' {
        Add-WUPathEnvironmentVariable -Path 'c:\one\', 'c:\two' -Scope Process

        Should -Invoke -CommandName Set-WUEnvironmentVariableValue -ModuleName PSWinUtil -Times 0 -Exactly
    }

    It 'does not update PATH with WhatIf' {
        Add-WUPathEnvironmentVariable -Path 'C:\Three' -WhatIf

        Should -Invoke -CommandName Set-WUEnvironmentVariableValue -ModuleName PSWinUtil -Times 0 -Exactly
    }
}

Describe 'Remove-WUPathEnvironmentVariable' {
    BeforeEach {
        Mock -CommandName Get-WUEnvironmentVariableValue -ModuleName PSWinUtil -MockWith {
            'C:\One;C:\Tools;C:\Two;C:\TOOLS\'
        }
        Mock -CommandName Set-WUEnvironmentVariableValue -ModuleName PSWinUtil -MockWith {}
    }

    It 'removes every normalized match and preserves other items' {
        Remove-WUPathEnvironmentVariable -Path 'c:\tools\' -Scope Machine

        Should -Invoke -CommandName Set-WUEnvironmentVariableValue -ModuleName PSWinUtil -Times 1 -Exactly -ParameterFilter {
            $Name -eq 'Path' -and $Value -eq 'C:\One;C:\Two' -and $Scope -eq 'Machine'
        }
    }

    It 'does nothing when no path matches' {
        Remove-WUPathEnvironmentVariable -Path 'C:\Missing'

        Should -Invoke -CommandName Set-WUEnvironmentVariableValue -ModuleName PSWinUtil -Times 0 -Exactly
    }

    It 'does not update PATH with WhatIf' {
        Remove-WUPathEnvironmentVariable -Path 'C:\Tools' -WhatIf

        Should -Invoke -CommandName Set-WUEnvironmentVariableValue -ModuleName PSWinUtil -Times 0 -Exactly
    }
}
