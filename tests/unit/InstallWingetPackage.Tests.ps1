BeforeAll {
    . (Join-Path -Path $PSScriptRoot -ChildPath '../UnitTestBootstrap.ps1')
}

Describe 'Install-WUWingetPackage' {
    BeforeEach {
        InModuleScope -ModuleName PSWinUtil {
            function script:winget.exe {
                $script:CapturedWingetArguments = @($args)
                $global:LASTEXITCODE = 0
                'Package installed'
            }
        }
    }

    It 'installs an exact package and accepts both agreements' {
        $result = Install-WUWingetPackage -Id 'Microsoft.PowerShell'
        $capturedArguments = InModuleScope -ModuleName PSWinUtil {
            $script:CapturedWingetArguments
        }

        $result | Should -Be 'Package installed'
        $capturedArguments -join '|' | Should -Be (
            'install|--id|Microsoft.PowerShell|--exact|' +
            '--accept-source-agreements|--accept-package-agreements'
        )
    }

    It 'does not invoke winget with WhatIf' {
        Install-WUWingetPackage -Id 'Microsoft.PowerShell' -WhatIf
    }

    It 'reports the exit code and output when winget fails' {
        InModuleScope -ModuleName PSWinUtil {
            function script:winget.exe {
                $global:LASTEXITCODE = 42
                'Installation failed'
            }
        }

        {
            Install-WUWingetPackage -Id 'Microsoft.PowerShell'
        } | Should -Throw '*exit code 42*Installation failed*'
    }
}
