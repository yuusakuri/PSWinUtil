Describe 'Install-WUWingetPackage' {
    BeforeEach {
        InModuleScope -ModuleName PSWinUtil {
            function script:Invoke-WUTestWinget {
                $script:CapturedWingetArguments = @($args)
                $global:LASTEXITCODE = 0
                'Package installed'
            }
        }
        Mock -CommandName Get-Command -ModuleName PSWinUtil -MockWith {
            [pscustomobject]@{ Source = 'Invoke-WUTestWinget' }
            [pscustomobject]@{ Source = 'unused-winget.exe' }
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
        Should -Invoke -CommandName Get-Command -ModuleName PSWinUtil -Times 1 -Exactly -ParameterFilter {
            $Name -eq 'winget.exe' -and $CommandType -eq 'Application'
        }
    }

    It 'does not invoke winget with WhatIf' {
        Install-WUWingetPackage -Id 'Microsoft.PowerShell' -WhatIf

        Should -Invoke -CommandName Get-Command -ModuleName PSWinUtil -Times 0 -Exactly
    }

    It 'reports the exit code and output when winget fails' {
        InModuleScope -ModuleName PSWinUtil {
            function script:Invoke-WUTestWinget {
                $global:LASTEXITCODE = 42
                'Installation failed'
            }
        }

        {
            Install-WUWingetPackage -Id 'Microsoft.PowerShell'
        } | Should -Throw '*exit code 42*Installation failed*'
    }
}
