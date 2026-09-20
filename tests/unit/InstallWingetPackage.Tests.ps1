BeforeAll {
    . (Join-Path -Path $PSScriptRoot -ChildPath '../UnitTestBootstrap.ps1')
}

Describe 'Install-WUWingetPackage' {
    BeforeEach {
        Mock -CommandName Invoke-WUNativeCommand -ModuleName PSWinUtil -MockWith {
            InModuleScope -ModuleName PSWinUtil -Parameters @{ Arguments = $ArgumentList } {
                $script:CapturedWingetArguments = @($Arguments)
            }
            [PSWinUtil.NativeCommandResult]::new($true, 0, $null, $null)
        }
    }

    It 'installs an exact package and accepts both agreements' {
        Install-WUWingetPackage -Id 'Microsoft.PowerShell'
        $capturedArguments = InModuleScope -ModuleName PSWinUtil {
            $script:CapturedWingetArguments
        }

        $capturedArguments -join '|' | Should -Be (
            'install|--id|Microsoft.PowerShell|--exact|' +
            '--accept-source-agreements|--accept-package-agreements'
        )
    }

    It 'does not invoke winget with WhatIf' {
        Install-WUWingetPackage -Id 'Microsoft.PowerShell' -WhatIf
    }

    It 'reports the exit code when winget fails' {
        Mock -CommandName Invoke-WUNativeCommand -ModuleName PSWinUtil -MockWith {
            throw 'winget.exe failed with exit code 42'
        }

        {
            Install-WUWingetPackage -Id 'Microsoft.PowerShell'
        } | Should -Throw '*exit code 42*'
    }
}
