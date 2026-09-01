BeforeAll {
    . (Join-Path -Path $PSScriptRoot -ChildPath '../UnitTestBootstrap.ps1')
}

Describe 'Install-WUGitHubCli' {
    BeforeEach {
        Mock -CommandName Install-WUWingetPackage -ModuleName PSWinUtil -MockWith {
            'GitHub CLI installed'
        }
    }

    It 'installs the exact GitHub CLI package through the winget installer' {
        $result = Install-WUGitHubCli

        $result | Should -Be 'GitHub CLI installed'
        Should -Invoke -CommandName Install-WUWingetPackage -ModuleName PSWinUtil -Times 1 -Exactly -ParameterFilter {
            $Id -eq 'GitHub.cli'
        }
    }

    It 'forwards WhatIf to the winget installer' {
        Install-WUGitHubCli -WhatIf

        Should -Invoke -CommandName Install-WUWingetPackage -ModuleName PSWinUtil -Times 1 -Exactly -ParameterFilter {
            $Id -eq 'GitHub.cli' -and $WhatIf -eq $true
        }
    }
}
