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
    BeforeAll {
        InModuleScope -ModuleName PSWinUtil {
            function script:winget.exe {
                param([Parameter(ValueFromRemainingArguments = $true)][string[]]$Arguments)

                $Arguments | Out-Null
                throw 'The package manager must be replaced by the test backend.'
            }
        }
    }

    BeforeEach {
        $script:OriginalPath = $env:PATH
        $script:OriginalProgramFiles = $env:ProgramFiles
        $script:OriginalProgramFilesX86 = ${env:ProgramFiles(x86)}
        $script:OriginalLocalAppData = $env:LOCALAPPDATA
        $script:FixtureRoot = Join-Path -Path $TestDrive -ChildPath ([guid]::NewGuid().ToString('N'))
        $script:GitDirectory = Join-Path -Path $script:FixtureRoot -ChildPath 'installed Git'
        $script:GitCommandDirectory = Join-Path -Path $script:GitDirectory -ChildPath 'cmd'
        New-Item -Path $script:GitCommandDirectory -ItemType Directory -Force | Out-Null
        [IO.File]::WriteAllText((Join-Path -Path $script:GitCommandDirectory -ChildPath 'git.exe'), 'existing Git')
        $env:PATH = Join-Path -Path $script:FixtureRoot -ChildPath 'other tools'
        $script:InitialPath = $env:PATH
        $env:ProgramFiles = $script:FixtureRoot
        ${env:ProgramFiles(x86)} = $script:FixtureRoot
        $env:LOCALAPPDATA = $script:FixtureRoot
        $script:InstalledPackages = @()
        $script:ProduceInstalledFiles = $true
        $script:PersistentPaths = @{}

        Mock -CommandName Get-WURegistryProperty -ModuleName PSWinUtil -MockWith {
            if ($Path -eq 'Registry::HKEY_LOCAL_MACHINE\SOFTWARE\GitForWindows' -and $Name -eq 'InstallPath') {
                [pscustomobject]@{ Value = $script:GitDirectory }
            }
        }
        Mock -CommandName Set-WUEnvironmentVariable -ModuleName PSWinUtil -MockWith {
            param($Name, $Value, $Scope, [switch]$WhatIf)

            if ($WhatIf -or $WhatIfPreference) {
                return
            }
            foreach ($targetScope in $Scope) {
                if ($targetScope -eq 'Process') {
                    [Environment]::SetEnvironmentVariable($Name, $Value, 'Process')
                } else {
                    $script:PersistentPaths[$targetScope] = $Value
                }
            }
        }
        Mock -CommandName winget.exe -ModuleName PSWinUtil -MockWith {
            param([string[]]$Arguments)

            $packageIndex = [Array]::IndexOf($Arguments, '--id') + 1
            $packageId = $Arguments[$packageIndex]
            $script:InstalledPackages += $packageId
            if ($packageId -eq 'Git.Git' -and $script:ProduceInstalledFiles) {
                [IO.File]::WriteAllText((Join-Path -Path $script:GitCommandDirectory -ChildPath 'git.exe'), 'new Git')
            }
            $global:LASTEXITCODE = 0
            'Package installation completed'
        }
    }

    AfterEach {
        $env:PATH = $script:OriginalPath
        $env:ProgramFiles = $script:OriginalProgramFiles
        ${env:ProgramFiles(x86)} = $script:OriginalProgramFilesX86
        $env:LOCALAPPDATA = $script:OriginalLocalAppData
    }

    It 'makes an existing Git installation available without downloading it again' {
        Install-WUGit

        Test-WUCommand -Name 'git.exe' | Should -BeTrue
        $env:PATH.Split(';') | Should -Contain $script:InitialPath
        [IO.File]::ReadAllText((Join-Path -Path $script:GitCommandDirectory -ChildPath 'git.exe')) | Should -Be 'existing Git'
        $script:InstalledPackages | Should -HaveCount 0
    }

    It 'makes Git available in every requested PATH scope' {
        Install-WUGit -Scope Process, Machine

        Test-WUCommand -Name 'git.exe' | Should -BeTrue
        $script:PersistentPaths['Machine'].Split(';') | Should -Contain $script:GitCommandDirectory
    }

    It 'makes a newly installed Git available from the installation location' {
        Remove-Item -LiteralPath (Join-Path -Path $script:GitCommandDirectory -ChildPath 'git.exe')
        Install-WUGit

        Test-WUCommand -Name 'git.exe' | Should -BeTrue
        $env:PATH.Split(';') | Should -Contain $script:GitCommandDirectory
        [IO.File]::ReadAllText((Join-Path -Path $script:GitCommandDirectory -ChildPath 'git.exe')) | Should -Be 'new Git'
        $script:InstalledPackages | Should -Be @('Git.Git')
    }

    It 'leaves PATH and an existing Git unchanged when previewing installation' {
        Install-WUGit -Scope Process, Machine -WhatIf

        $env:PATH | Should -Be $script:InitialPath
        $script:PersistentPaths.Count | Should -Be 0
        $script:InstalledPackages | Should -HaveCount 0
        [IO.File]::ReadAllText((Join-Path -Path $script:GitCommandDirectory -ChildPath 'git.exe')) | Should -Be 'existing Git'
    }

    It 'does not install Git or change PATH when previewing a missing installation' {
        $commandPath = Join-Path -Path $script:GitCommandDirectory -ChildPath 'git.exe'
        Remove-Item -LiteralPath $commandPath
        Install-WUGit -WhatIf

        $env:PATH | Should -Be $script:InitialPath
        Test-Path -LiteralPath $commandPath | Should -BeFalse
        $script:InstalledPackages | Should -HaveCount 0
    }

    It 'reports a missing installation without adding an unusable PATH entry' {
        Remove-Item -LiteralPath (Join-Path -Path $script:GitCommandDirectory -ChildPath 'git.exe')
        $script:ProduceInstalledFiles = $false

        { Install-WUGit } | Should -Throw '*installation directory was not found*'
        $env:PATH | Should -Be $script:InitialPath
        $script:PersistentPaths.Count | Should -Be 0
    }
}
