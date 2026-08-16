BeforeAll {
    $repositoryRoot = Split-Path -Path (Split-Path -Path $PSScriptRoot -Parent) -Parent
    $manifestPath = Join-Path -Path $repositoryRoot -ChildPath 'output/PSWinUtil/PSWinUtil.psd1'
    Import-Module -Name $manifestPath -Force -ErrorAction Stop

    $script:WinlogonPath = 'Registry::HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon'
    $script:SecurePassword = [securestring]::new()
    foreach ($character in 'UnitTestPassword'.ToCharArray()) {
        $script:SecurePassword.AppendChar($character)
    }
    $script:SecurePassword.MakeReadOnly()
}

Describe 'Get-WUWindowsAutoLogon' {
    BeforeEach {
        Mock -CommandName Get-WURegistryProperty -ModuleName PSWinUtil -MockWith {
            $values = @{
                AutoAdminLogon = '1'
                DefaultUserName = 'ExampleUser'
                DefaultDomainName = 'EXAMPLE'
            }
            if ($values.ContainsKey($Name)) {
                [pscustomobject]@{
                    Name = $Name
                    Value = $values[$Name]
                    Type = 'String'
                }
            }
        }
    }

    It 'returns the enabled state without a password' {
        $result = Get-WUWindowsAutoLogon

        $result.Enabled | Should -BeTrue
        $result.UserName | Should -Be 'ExampleUser'
        $result.Domain | Should -Be 'EXAMPLE'
        $result.PSObject.TypeNames | Should -Contain 'PSWinUtil.WindowsAutoLogon'
        $result.PSObject.Properties.Name | Should -Not -Contain 'Password'
        $result.PSObject.Properties.Name | Should -Not -Contain 'Secret'
    }

    It 'reads only non-secret Winlogon values' {
        $null = Get-WUWindowsAutoLogon

        Should -Invoke -CommandName Get-WURegistryProperty -ModuleName PSWinUtil -Times 3 -Exactly
        Should -Invoke -CommandName Get-WURegistryProperty -ModuleName PSWinUtil -Times 0 -Exactly -ParameterFilter {
            $Name -eq 'DefaultPassword'
        }
    }

    It 'returns a disabled state when values are missing' {
        Mock -CommandName Get-WURegistryProperty -ModuleName PSWinUtil

        $result = Get-WUWindowsAutoLogon

        $result.Enabled | Should -BeFalse
        $result.UserName | Should -BeNullOrEmpty
        $result.Domain | Should -BeNullOrEmpty
    }
}

Describe 'Enable-WUWindowsAutoLogon' {
    BeforeEach {
        $script:Calls = @()
        Mock -CommandName Set-WURegistryProperty -ModuleName PSWinUtil -MockWith {
            $script:Calls += "Set:$Name=$Value"
        }
        Mock -CommandName Remove-WURegistryProperty -ModuleName PSWinUtil -MockWith {
            $script:Calls += "Remove:$Name"
        }
        Mock -CommandName Set-WUAutoLogonPassword -ModuleName PSWinUtil -MockWith {
            $script:Calls += 'SetPassword'
        }
        Mock -CommandName Get-WUWindowsAutoLogon -ModuleName PSWinUtil -MockWith {
            [pscustomobject]@{
                PSTypeName = 'PSWinUtil.WindowsAutoLogon'
                Enabled = $true
                UserName = 'ExampleUser'
                Domain = 'EXAMPLE'
            }
        }
    }

    It 'uses a SecureString password parameter' {
        $command = Get-Command -Name Enable-WUWindowsAutoLogon -Module PSWinUtil

        $command.Parameters.Password.ParameterType | Should -Be ([securestring])
    }

    It 'stores account data and enables auto logon last' {
        $parameters = @{
            UserName = 'ExampleUser'
            Password = $script:SecurePassword
            Domain = 'EXAMPLE'
        }
        Enable-WUWindowsAutoLogon @parameters

        $script:Calls | Should -Be @(
            'Set:DefaultUserName=ExampleUser'
            'Set:DefaultDomainName=EXAMPLE'
            'SetPassword'
            'Set:AutoAdminLogon=1'
        )
        Should -Invoke -CommandName Set-WUAutoLogonPassword -ModuleName PSWinUtil -Times 1 -Exactly -ParameterFilter {
            $Password -is [securestring]
        }
    }

    It 'removes the default domain when Domain is omitted' {
        Enable-WUWindowsAutoLogon -UserName 'ExampleUser' -Password $script:SecurePassword

        $script:Calls | Should -Be @(
            'Set:DefaultUserName=ExampleUser'
            'Remove:DefaultDomainName'
            'SetPassword'
            'Set:AutoAdminLogon=1'
        )
    }

    It 'forwards WhatIf to every delegated change' {
        Enable-WUWindowsAutoLogon -UserName 'ExampleUser' -Password $script:SecurePassword -WhatIf

        Should -Invoke -CommandName Set-WURegistryProperty -ModuleName PSWinUtil -Times 2 -Exactly -ParameterFilter {
            $WhatIf
        }
        Should -Invoke -CommandName Remove-WURegistryProperty -ModuleName PSWinUtil -Times 1 -Exactly -ParameterFilter {
            $WhatIf
        }
        Should -Invoke -CommandName Set-WUAutoLogonPassword -ModuleName PSWinUtil -Times 1 -Exactly -ParameterFilter {
            $WhatIf
        }
    }

    It 'returns only non-secret state with PassThru' {
        $result = Enable-WUWindowsAutoLogon -UserName 'ExampleUser' -Password $script:SecurePassword -PassThru

        $result.Enabled | Should -BeTrue
        $result.PSObject.Properties.Name | Should -Not -Contain 'Password'
        Should -Invoke -CommandName Get-WUWindowsAutoLogon -ModuleName PSWinUtil -Times 1 -Exactly
    }
}

Describe 'Disable-WUWindowsAutoLogon' {
    BeforeEach {
        $script:Calls = @()
        Mock -CommandName Set-WURegistryProperty -ModuleName PSWinUtil -MockWith {
            $script:Calls += "Set:$Name=$Value"
        }
        Mock -CommandName Set-WUAutoLogonPassword -ModuleName PSWinUtil -MockWith {
            $script:Calls += 'RemovePassword'
        }
        Mock -CommandName Remove-WURegistryProperty -ModuleName PSWinUtil -MockWith {
            $script:Calls += "Remove:$Name"
        }
        Mock -CommandName Get-WUWindowsAutoLogon -ModuleName PSWinUtil -MockWith {
            [pscustomobject]@{
                PSTypeName = 'PSWinUtil.WindowsAutoLogon'
                Enabled = $false
                UserName = $null
                Domain = $null
            }
        }
    }

    It 'disables auto logon before removing account data' {
        Disable-WUWindowsAutoLogon

        $script:Calls | Should -Be @(
            'Set:AutoAdminLogon=0'
            'RemovePassword'
            'Remove:DefaultUserName'
            'Remove:DefaultDomainName'
        )
        Should -Invoke -CommandName Set-WUAutoLogonPassword -ModuleName PSWinUtil -Times 1 -Exactly -ParameterFilter {
            $null -eq $Password
        }
    }

    It 'forwards WhatIf to every delegated change' {
        Disable-WUWindowsAutoLogon -WhatIf

        Should -Invoke -CommandName Set-WURegistryProperty -ModuleName PSWinUtil -Times 1 -Exactly -ParameterFilter {
            $WhatIf
        }
        Should -Invoke -CommandName Set-WUAutoLogonPassword -ModuleName PSWinUtil -Times 1 -Exactly -ParameterFilter {
            $WhatIf
        }
        Should -Invoke -CommandName Remove-WURegistryProperty -ModuleName PSWinUtil -Times 2 -Exactly -ParameterFilter {
            $WhatIf
        }
    }

    It 'returns a disabled state with PassThru' {
        $result = Disable-WUWindowsAutoLogon -PassThru

        $result.Enabled | Should -BeFalse
        $result.PSObject.Properties.Name | Should -Not -Contain 'Password'
    }
}

Describe 'Set-WUAutoLogonPassword' {
    It 'does not load or call the Windows LSA API with WhatIf' {
        InModuleScope -ModuleName PSWinUtil {
            $password = [securestring]::new()
            foreach ($character in 'UnitTestPassword'.ToCharArray()) {
                $password.AppendChar($character)
            }
            $password.MakeReadOnly()

            { Set-WUAutoLogonPassword -Password $password -WhatIf } | Should -Not -Throw
            { Set-WUAutoLogonPassword -Password $null -WhatIf } | Should -Not -Throw
        }
    }
}
