BeforeAll {
    . (Join-Path -Path $PSScriptRoot -ChildPath '../UnitTestBootstrap.ps1')

    $script:WinlogonPath = 'Registry::HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon'
    $script:SecurePassword = [securestring]::new()
    foreach ($character in 'UnitTestPassword'.ToCharArray()) {
        $script:SecurePassword.AppendChar($character)
    }
    $script:SecurePassword.MakeReadOnly()
}

Describe 'Windows auto logon configuration' {
    BeforeEach {
        $script:Registry = @{
            "$($script:WinlogonPath)|AutoAdminLogon" = [pscustomobject]@{ Value = '1'; Type = 'String' }
            "$($script:WinlogonPath)|DefaultUserName" = [pscustomobject]@{ Value = 'ExampleUser'; Type = 'String' }
            "$($script:WinlogonPath)|DefaultDomainName" = [pscustomobject]@{ Value = 'EXAMPLE'; Type = 'String' }
            "$($script:WinlogonPath)|Unrelated" = [pscustomobject]@{ Value = 'keep'; Type = 'String' }
        }
        $script:StoredPassword = $script:SecurePassword
        Mock -CommandName Get-WURegistryProperty -ModuleName PSWinUtil -MockWith {
            if ($Name -eq 'DefaultPassword') {
                throw 'The registry password must never be read.'
            }
            $script:Registry["$Path|$Name"]
        }
        Mock -CommandName Test-Path -ModuleName PSWinUtil -ParameterFilter { $LiteralPath -like 'Registry::*' } -MockWith { $true }
        Mock -CommandName New-ItemProperty -ModuleName PSWinUtil -ParameterFilter { $LiteralPath -like 'Registry::*' } -MockWith {
            if ($Name -eq 'AutoAdminLogon' -and $Value -eq '1' -and $null -eq $script:StoredPassword) {
                throw 'Auto logon must not be enabled before the credential is stored.'
            }
            $script:Registry["$LiteralPath|$Name"] = [pscustomobject]@{ Value = $Value; Type = $PropertyType }
        }
        Mock -CommandName Remove-ItemProperty -ModuleName PSWinUtil -ParameterFilter { $LiteralPath -like 'Registry::*' } -MockWith {
            $script:Registry.Remove("$LiteralPath|$Name")
        }
        Mock -CommandName Set-WUAutoLogonPassword -ModuleName PSWinUtil -MockWith {
            param([securestring]$Password, [switch]$WhatIf)

            if ($WhatIf -or $WhatIfPreference) {
                return
            }
            if ($null -eq $Password -and $script:Registry["$($script:WinlogonPath)|AutoAdminLogon"].Value -ne '0') {
                throw 'Auto logon must be disabled before its credential is removed.'
            }
            $script:StoredPassword = $Password
        }
    }

    It 'returns enabled account information without reading or exposing a password' {
        $result = Get-WUWindowsAutoLogon

        $result.Enabled | Should -BeTrue
        $result.UserName | Should -Be 'ExampleUser'
        $result.Domain | Should -Be 'EXAMPLE'
        $result.PSObject.TypeNames | Should -Contain 'PSWinUtil.WindowsAutoLogon'
        $result.PSObject.Properties.Name | Should -Not -Contain 'Password'
        $result.PSObject.Properties.Name | Should -Not -Contain 'Secret'
    }

    It 'returns a disabled state when account values are absent' {
        $script:Registry.Clear()
        $result = Get-WUWindowsAutoLogon

        $result.Enabled | Should -BeFalse
        $result.UserName | Should -BeNullOrEmpty
        $result.Domain | Should -BeNullOrEmpty
    }

    It 'enables auto logon for the selected account with a secure credential' {
        $script:Registry["$($script:WinlogonPath)|AutoAdminLogon"].Value = '0'
        $script:StoredPassword = $null

        Enable-WUWindowsAutoLogon -UserName 'NewUser' -Password $script:SecurePassword -Domain 'NEWDOMAIN'
        $result = Get-WUWindowsAutoLogon

        $result.Enabled | Should -BeTrue
        $result.UserName | Should -Be 'NewUser'
        $result.Domain | Should -Be 'NEWDOMAIN'
        $script:StoredPassword | Should -BeOfType ([securestring])
        [object]::ReferenceEquals($script:StoredPassword, $script:SecurePassword) | Should -BeTrue
        $script:Registry.ContainsKey("$($script:WinlogonPath)|DefaultPassword") | Should -BeFalse
        $script:Registry["$($script:WinlogonPath)|Unrelated"].Value | Should -Be 'keep'
    }

    It 'removes a stale domain when enabling a local account' {
        Enable-WUWindowsAutoLogon -UserName 'LocalUser' -Password $script:SecurePassword
        $result = Get-WUWindowsAutoLogon

        $result.Enabled | Should -BeTrue
        $result.UserName | Should -Be 'LocalUser'
        $result.Domain | Should -BeNullOrEmpty
        $script:Registry.ContainsKey("$($script:WinlogonPath)|DefaultDomainName") | Should -BeFalse
    }

    It 'preserves account information and credentials when previewing enablement' {
        $originalPassword = [securestring]::new()
        $originalPassword.MakeReadOnly()
        $script:StoredPassword = $originalPassword
        Enable-WUWindowsAutoLogon -UserName 'NewUser' -Password $script:SecurePassword -WhatIf
        $result = Get-WUWindowsAutoLogon

        $result.Enabled | Should -BeTrue
        $result.UserName | Should -Be 'ExampleUser'
        $result.Domain | Should -Be 'EXAMPLE'
        $script:Registry.Count | Should -Be 4
        [object]::ReferenceEquals($script:StoredPassword, $originalPassword) | Should -BeTrue
    }

    It 'returns the resulting account state without a password when enabling with PassThru' {
        $result = Enable-WUWindowsAutoLogon -UserName 'NewUser' -Password $script:SecurePassword -Domain 'NEWDOMAIN' -PassThru

        $result.Enabled | Should -BeTrue
        $result.UserName | Should -Be 'NewUser'
        $result.Domain | Should -Be 'NEWDOMAIN'
        $result.PSObject.Properties.Name | Should -Not -Contain 'Password'
        $result.PSObject.Properties.Name | Should -Not -Contain 'Secret'
    }

    It 'disables auto logon and removes its account and credential while preserving other settings' {
        Disable-WUWindowsAutoLogon
        $result = Get-WUWindowsAutoLogon

        $result.Enabled | Should -BeFalse
        $result.UserName | Should -BeNullOrEmpty
        $result.Domain | Should -BeNullOrEmpty
        $script:StoredPassword | Should -BeNullOrEmpty
        $script:Registry.Count | Should -Be 2
        $script:Registry["$($script:WinlogonPath)|Unrelated"].Value | Should -Be 'keep'
    }

    It 'preserves account information and credentials when previewing disablement' {
        Disable-WUWindowsAutoLogon -WhatIf
        $result = Get-WUWindowsAutoLogon

        $result.Enabled | Should -BeTrue
        $result.UserName | Should -Be 'ExampleUser'
        $result.Domain | Should -Be 'EXAMPLE'
        $script:Registry.Count | Should -Be 4
        [object]::ReferenceEquals($script:StoredPassword, $script:SecurePassword) | Should -BeTrue
    }

    It 'returns the resulting disabled state without a password when disabling with PassThru' {
        $result = Disable-WUWindowsAutoLogon -PassThru

        $result.Enabled | Should -BeFalse
        $result.UserName | Should -BeNullOrEmpty
        $result.Domain | Should -BeNullOrEmpty
        $result.PSObject.Properties.Name | Should -Not -Contain 'Password'
        $result.PSObject.Properties.Name | Should -Not -Contain 'Secret'
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
