BeforeAll {
    . (Join-Path -Path $PSScriptRoot -ChildPath '../UnitTestBootstrap.ps1')

    $script:UserRunPath = 'Registry::HKEY_CURRENT_USER\Software\Microsoft\Windows\CurrentVersion\Run'
    $script:MachineRunPath = 'Registry::HKEY_LOCAL_MACHINE\Software\Microsoft\Windows\CurrentVersion\Run'
}



Describe 'Get-WUStartupEntry' {
    BeforeEach {
        Mock -CommandName Test-Path -ModuleName PSWinUtil -MockWith { $true }
        Mock -CommandName Get-Item -ModuleName PSWinUtil -MockWith {
            $scopeName = if ($LiteralPath -like '*HKEY_CURRENT_USER*') { 'User' } else { 'Machine' }
            $key = [pscustomobject]@{
                Values = [ordered]@{
                    ExampleApp = "$scopeName command"
                    AnotherApp = "$scopeName second"
                    '' = 'ignored default value'
                }
            }
            $key | Add-Member -MemberType ScriptMethod -Name GetValueNames -Value {
                @($this.Values.Keys)
            }
            $key | Add-Member -MemberType ScriptMethod -Name GetValue -Value {
                param($Name, $DefaultValue, $Options)

                $null = $DefaultValue
                $null = $Options
                $this.Values[$Name]
            }
            $key
        }
    }

    It 'gets all named entries from both scopes' {
        $entries = @(Get-WUStartupEntry)

        $entries.Count | Should -Be 4
        @($entries.Scope) | Should -Contain 'User'
        @($entries.Scope) | Should -Contain 'Machine'
        $entries[0].PSObject.TypeNames | Should -Contain 'PSWinUtil.StartupEntry'
    }

    It 'filters by registry name and scope without case differences' {
        $entries = @(Get-WUStartupEntry -Name 'exampleapp' -Scope User)

        $entries.Count | Should -Be 1
        $entries[0].Name | Should -Be 'ExampleApp'
        $entries[0].Scope | Should -Be 'User'
        $entries[0].CommandLine | Should -Be 'User command'
    }

    It 'gets entries from multiple explicitly selected scopes' {
        $entries = @(Get-WUStartupEntry -Name 'ExampleApp' -Scope User, Machine)

        $entries | Should -HaveCount 2
        $entries.Scope | Should -Contain 'User'
        $entries.Scope | Should -Contain 'Machine'
    }

    It 'returns no output for a missing Run key' {
        Mock -CommandName Test-Path -ModuleName PSWinUtil -MockWith { $false }

        Get-WUStartupEntry -Scope User | Should -BeNullOrEmpty
        Should -Invoke -CommandName Get-Item -ModuleName PSWinUtil -Times 0 -Exactly
    }
}




