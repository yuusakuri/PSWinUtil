BeforeAll {
    . (Join-Path -Path $PSScriptRoot -ChildPath '../UnitTestBootstrap.ps1')

    InModuleScope -ModuleName PSWinUtil {
        function script:winget.exe {
            param([Parameter(ValueFromRemainingArguments = $true)][string[]]$Arguments)

            $Arguments | Out-Null
            throw 'The package manager must be replaced by the test backend.'
        }
    }
}

Describe 'Install-WUGitHubCli' {
    BeforeEach {
        $script:InstalledPackages = @()
        $script:PackageExitCode = 0
        Mock -CommandName winget.exe -ModuleName PSWinUtil -MockWith {
            param([string[]]$Arguments)

            $packageIndex = [Array]::IndexOf($Arguments, '--id') + 1
            if ($script:PackageExitCode -eq 0) {
                $script:InstalledPackages += $Arguments[$packageIndex]
            }
            $global:LASTEXITCODE = $script:PackageExitCode
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
