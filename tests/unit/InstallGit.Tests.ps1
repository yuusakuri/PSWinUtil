BeforeAll {
    . (Join-Path -Path $PSScriptRoot -ChildPath '../UnitTestBootstrap.ps1')
}

Describe 'Get-WUGitInstallPath' {
    It 'returns the installation directory recorded in the registry' {
        Mock -CommandName Get-WURegistryProperty -ModuleName PSWinUtil -MockWith {
            if ($Path -eq 'Registry::HKEY_LOCAL_MACHINE\SOFTWARE\GitForWindows') {
                [pscustomobject]@{ Value = 'D:\Tools\Git' }
            }
        }
        Mock -CommandName Test-Path -ModuleName PSWinUtil -MockWith {
            $LiteralPath -eq 'D:\Tools\Git\cmd\git.exe'
        }

        InModuleScope -ModuleName PSWinUtil { Get-WUGitInstallPath } |
            Should -Be 'D:\Tools\Git'
    }

    It 'falls back to the default machine installation directory' {
        Mock -CommandName Get-WURegistryProperty -ModuleName PSWinUtil
        Mock -CommandName Test-Path -ModuleName PSWinUtil -MockWith {
            $LiteralPath -eq (Join-Path -Path $env:ProgramFiles -ChildPath 'Git\cmd\git.exe')
        }

        InModuleScope -ModuleName PSWinUtil { Get-WUGitInstallPath } |
            Should -Be (Join-Path -Path $env:ProgramFiles -ChildPath 'Git')
    }

    It 'returns nothing when the command is missing in every candidate directory' {
        Mock -CommandName Get-WURegistryProperty -ModuleName PSWinUtil -MockWith {
            [pscustomobject]@{ Value = 'D:\Removed\Git' }
        }
        Mock -CommandName Test-Path -ModuleName PSWinUtil -MockWith { $false }

        InModuleScope -ModuleName PSWinUtil { Get-WUGitInstallPath } |
            Should -BeNullOrEmpty
    }
}

Describe 'Install-WUGit' {
    BeforeEach {
        $script:GitInstallPaths = @('C:\Program Files\Git')
        $script:GitInstallPathCallCount = 0
        Mock -CommandName Get-WUGitInstallPath -ModuleName PSWinUtil -MockWith {
            $script:GitInstallPathCallCount++
            $lastIndex = $script:GitInstallPaths.Count - 1
            $resultIndex = [Math]::Min($script:GitInstallPathCallCount - 1, $lastIndex)
            $script:GitInstallPaths[$resultIndex]
        }
        Mock -CommandName Install-WUWingetPackage -ModuleName PSWinUtil -MockWith {
            'Git for Windows installed'
        }
        Mock -CommandName Add-WUPathEnvironmentVariable -ModuleName PSWinUtil
    }

    It 'adds the command directory of an existing installation without using winget' {
        Install-WUGit

        Should -Invoke -CommandName Install-WUWingetPackage -ModuleName PSWinUtil -Times 0 -Exactly
        Should -Invoke -CommandName Add-WUPathEnvironmentVariable -ModuleName PSWinUtil -Times 1 -Exactly -ParameterFilter {
            $Path -eq 'C:\Program Files\Git\cmd' -and
            (@($Scope) -join '|') -eq 'Process'
        }
    }

    It 'adds the command directory to every requested scope' {
        Install-WUGit -Scope Process, Machine

        Should -Invoke -CommandName Add-WUPathEnvironmentVariable -ModuleName PSWinUtil -Times 1 -Exactly -ParameterFilter {
            (@($Scope) -join '|') -eq 'Process|Machine'
        }
    }

    It 'installs the exact package and uses the directory detected after the installation' {
        $script:GitInstallPaths = @($null, 'D:\Tools\Git')

        Install-WUGit

        Should -Invoke -CommandName Install-WUWingetPackage -ModuleName PSWinUtil -Times 1 -Exactly -ParameterFilter {
            $Id -eq 'Git.Git'
        }
        Should -Invoke -CommandName Get-WUGitInstallPath -ModuleName PSWinUtil -Times 2 -Exactly
        Should -Invoke -CommandName Add-WUPathEnvironmentVariable -ModuleName PSWinUtil -Times 1 -Exactly -ParameterFilter {
            $Path -eq 'D:\Tools\Git\cmd'
        }
    }

    It 'forwards WhatIf to the delegated commands' {
        Install-WUGit -WhatIf

        Should -Invoke -CommandName Add-WUPathEnvironmentVariable -ModuleName PSWinUtil -Times 1 -Exactly -ParameterFilter {
            $WhatIf -eq $true
        }
    }

    It 'does not change PATH with WhatIf while Git is missing' {
        $script:GitInstallPaths = @($null)

        { Install-WUGit -WhatIf } | Should -Not -Throw

        Should -Invoke -CommandName Install-WUWingetPackage -ModuleName PSWinUtil -Times 1 -Exactly -ParameterFilter {
            $Id -eq 'Git.Git' -and $WhatIf -eq $true
        }
        Should -Invoke -CommandName Add-WUPathEnvironmentVariable -ModuleName PSWinUtil -Times 0 -Exactly
    }

    It 'reports a missing installation directory after the installation' {
        $script:GitInstallPaths = @($null)

        { Install-WUGit } | Should -Throw '*installation directory was not found*'

        Should -Invoke -CommandName Add-WUPathEnvironmentVariable -ModuleName PSWinUtil -Times 0 -Exactly
    }
}
