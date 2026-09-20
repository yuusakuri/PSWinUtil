BeforeAll {
    . (Join-Path -Path $PSScriptRoot -ChildPath '../UnitTestBootstrap.ps1')
}

Describe 'Install-WUGit' {
    BeforeEach {
        $script:GitAvailable = $false
        Mock -CommandName Test-WUCommand -ModuleName PSWinUtil -MockWith {
            $script:GitAvailable
        }
        Mock -CommandName Install-WUWingetPackage -ModuleName PSWinUtil -MockWith {
            param([switch]$WhatIf)

            if (-not $WhatIf -and -not $WhatIfPreference) {
                $script:GitAvailable = $true
            }
        }
        Mock -CommandName Update-WUProcessEnvironment -ModuleName PSWinUtil
    }

    It 'does not install Git when the command is already available' {
        $script:GitAvailable = $true

        Install-WUGit

        Should -Invoke -CommandName Install-WUWingetPackage -ModuleName PSWinUtil -Times 0 -Exactly
        Should -Invoke -CommandName Update-WUProcessEnvironment -ModuleName PSWinUtil -Times 0 -Exactly
    }

    It 'installs Git and refreshes the current process when the command is missing' {
        Install-WUGit

        Should -Invoke -CommandName Install-WUWingetPackage -ModuleName PSWinUtil -Times 1 -Exactly -ParameterFilter {
            $Id -eq 'Git.Git'
        }
        Should -Invoke -CommandName Update-WUProcessEnvironment -ModuleName PSWinUtil -Times 1 -Exactly
        $script:GitAvailable | Should -BeTrue
    }

    It 'does not install or refresh the process during WhatIf' {
        Install-WUGit -WhatIf

        Should -Invoke -CommandName Install-WUWingetPackage -ModuleName PSWinUtil -Times 1 -Exactly -ParameterFilter {
            $Id -eq 'Git.Git' -and $WhatIf
        }
        Should -Invoke -CommandName Update-WUProcessEnvironment -ModuleName PSWinUtil -Times 0 -Exactly
        $script:GitAvailable | Should -BeFalse
    }

    It 'reports when Git is still unavailable after installation' {
        Mock -CommandName Install-WUWingetPackage -ModuleName PSWinUtil

        { Install-WUGit } | Should -Throw "Command 'git.exe' is not available."

        Should -Invoke -CommandName Update-WUProcessEnvironment -ModuleName PSWinUtil -Times 1 -Exactly
    }
}
