BeforeAll {
    $repositoryRoot = Split-Path -Path (Split-Path -Path $PSScriptRoot -Parent) -Parent
    $manifestPath = Join-Path -Path $repositoryRoot -ChildPath 'output/PSWinUtil/PSWinUtil.psd1'
    Import-Module -Name $manifestPath -Force -ErrorAction Stop

    $script:EnvironmentTarget = [System.EnvironmentVariableTarget]::Process
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
        $script:OriginalPathValue = [System.Environment]::GetEnvironmentVariable(
            'Path',
            $script:EnvironmentTarget
        )
        [System.Environment]::SetEnvironmentVariable(
            'Path',
            'C:\One;C:\Two\',
            $script:EnvironmentTarget
        )
        Mock -CommandName Set-WUEnvironmentVariable -ModuleName PSWinUtil -MockWith {}
    }

    AfterEach {
        [System.Environment]::SetEnvironmentVariable(
            'Path',
            $script:OriginalPathValue,
            $script:EnvironmentTarget
        )
    }

    It 'appends new paths and ignores normalized duplicates' {
        Add-WUPathEnvironmentVariable -Path 'c:\one\', 'C:\Three', 'c:\three\' -Scope Process

        Should -Invoke -CommandName Set-WUEnvironmentVariable -ModuleName PSWinUtil -Times 1 -Exactly -ParameterFilter {
            $Name -eq 'Path' -and
            $Value -eq 'C:\One;C:\Two\;C:\Three' -and
            $Scope -eq 'Process'
        }
    }

    It 'prepends new paths in input order' {
        Add-WUPathEnvironmentVariable -Path 'C:\Three', 'C:\Four' -Scope Process -Prepend

        Should -Invoke -CommandName Set-WUEnvironmentVariable -ModuleName PSWinUtil -Times 1 -Exactly -ParameterFilter {
            $Value -eq 'C:\Three;C:\Four;C:\One;C:\Two\'
        }
    }

    It 'does nothing when every path already exists' {
        Add-WUPathEnvironmentVariable -Path 'c:\one\', 'c:\two' -Scope Process

        Should -Invoke -CommandName Set-WUEnvironmentVariable -ModuleName PSWinUtil -Times 0 -Exactly
    }

    It 'forwards WhatIf to Set-WUEnvironmentVariable' {
        Add-WUPathEnvironmentVariable -Path 'C:\Three' -WhatIf

        Should -Invoke -CommandName Set-WUEnvironmentVariable -ModuleName PSWinUtil -Times 1 -Exactly -ParameterFilter {
            $WhatIf
        }
    }
}

Describe 'Remove-WUPathEnvironmentVariable' {
    BeforeEach {
        $script:OriginalPathValue = [System.Environment]::GetEnvironmentVariable(
            'Path',
            $script:EnvironmentTarget
        )
        [System.Environment]::SetEnvironmentVariable(
            'Path',
            'C:\One;C:\Tools;C:\Two;C:\TOOLS\',
            $script:EnvironmentTarget
        )
        Mock -CommandName Set-WUEnvironmentVariable -ModuleName PSWinUtil -MockWith {}
    }

    AfterEach {
        [System.Environment]::SetEnvironmentVariable(
            'Path',
            $script:OriginalPathValue,
            $script:EnvironmentTarget
        )
    }

    It 'removes every normalized match and preserves other items' {
        Remove-WUPathEnvironmentVariable -Path 'c:\tools\' -Scope Process

        Should -Invoke -CommandName Set-WUEnvironmentVariable -ModuleName PSWinUtil -Times 1 -Exactly -ParameterFilter {
            $Name -eq 'Path' -and
            $Value -eq 'C:\One;C:\Two' -and
            $Scope -eq 'Process'
        }
    }

    It 'does nothing when no path matches' {
        Remove-WUPathEnvironmentVariable -Path 'C:\Missing'

        Should -Invoke -CommandName Set-WUEnvironmentVariable -ModuleName PSWinUtil -Times 0 -Exactly
    }

    It 'forwards WhatIf to Set-WUEnvironmentVariable' {
        Remove-WUPathEnvironmentVariable -Path 'C:\Tools' -WhatIf

        Should -Invoke -CommandName Set-WUEnvironmentVariable -ModuleName PSWinUtil -Times 1 -Exactly -ParameterFilter {
            $WhatIf
        }
    }
}
