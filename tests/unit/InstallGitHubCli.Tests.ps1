BeforeAll {
    . (Join-Path -Path $PSScriptRoot -ChildPath '../UnitTestBootstrap.ps1')
}

Describe 'Install-WUGitHubCli' {
    BeforeEach {
        $script:InstalledPackages = @()
        $script:PackageExitCode = 0
        Mock -CommandName Install-WUWingetPackage -ModuleName PSWinUtil -MockWith {
            param($Id, [switch]$WhatIf)

            if ($WhatIf -or $WhatIfPreference) {
                return
            }
            if ($script:PackageExitCode -ne 0) {
                throw "winget.exe failed with exit code $script:PackageExitCode. Package manager output"
            }
            $script:InstalledPackages += $Id
            'Package manager output'
        }
    }

    It 'installs GitHub CLI and returns the package manager output' {
        $result = Install-WUGitHubCli

        $script:InstalledPackages | Should -Be @('GitHub.cli')
        $result | Should -Be 'Package manager output'
    }

    It 'does not install any package when previewing installation' {
        Install-WUGitHubCli -WhatIf

        $script:InstalledPackages | Should -HaveCount 0
    }

    It 'reports an unsuccessful installation' {
        $script:PackageExitCode = 7

        { Install-WUGitHubCli } | Should -Throw '*exit code 7*Package manager output*'
        $script:InstalledPackages | Should -HaveCount 0
    }
}
