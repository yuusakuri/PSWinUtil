BeforeAll {
    $repositoryRoot = Split-Path -Path (Split-Path -Path $PSScriptRoot -Parent) -Parent
    $manifestPath = Join-Path -Path $repositoryRoot -ChildPath 'output/PSWinUtil/PSWinUtil.psd1'
    Import-Module -Name $manifestPath -Force -ErrorAction Stop

    $script:UserRunPath = 'Registry::HKEY_CURRENT_USER\Software\Microsoft\Windows\CurrentVersion\Run'
    $script:MachineRunPath = 'Registry::HKEY_LOCAL_MACHINE\Software\Microsoft\Windows\CurrentVersion\Run'
}

Describe 'ConvertTo-WUWindowsCommandLineArgument' {
    It 'leaves a simple argument unquoted' {
        InModuleScope -ModuleName PSWinUtil {
            ConvertTo-WUWindowsCommandLineArgument -Argument '--minimized' |
                Should -Be '--minimized'
        }
    }

    It 'quotes spaces, quotation marks, and trailing backslashes' {
        InModuleScope -ModuleName PSWinUtil {
            ConvertTo-WUWindowsCommandLineArgument -Argument 'two words' |
                Should -Be '"two words"'
            ConvertTo-WUWindowsCommandLineArgument -Argument 'say"hello' |
                Should -Be '"say\"hello"'
            ConvertTo-WUWindowsCommandLineArgument -Argument 'C:\Path\' -AlwaysQuote |
                Should -Be '"C:\Path\\"'
        }
    }
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

Describe 'Register-WUStartupEntry' {
    BeforeEach {
        Mock -CommandName ConvertTo-WUFullPath -ModuleName PSWinUtil -MockWith {
            'C:\Program Files\Example\app.exe'
        }
        Mock -CommandName Assert-WUPathProperty -ModuleName PSWinUtil
        Mock -CommandName Set-WURegistryProperty -ModuleName PSWinUtil
        Mock -CommandName Get-WUStartupEntry -ModuleName PSWinUtil -MockWith {
            foreach ($currentScope in @($Scope)) {
                [pscustomobject]@{
                    PSTypeName = 'PSWinUtil.StartupEntry'
                    Name = $Name
                    Scope = $currentScope
                    CommandLine = 'stored command'
                }
            }
        }
    }

    It 'stores a fully qualified command line in the user Run key' {
        $parameters = @{
            Name = 'ExampleApp'
            FilePath = '.\app.exe'
            ArgumentList = @('--minimized', 'two words')
        }
        Register-WUStartupEntry @parameters

        Should -Invoke -CommandName ConvertTo-WUFullPath -ModuleName PSWinUtil -Times 1 -Exactly
        Should -Invoke -CommandName Assert-WUPathProperty -ModuleName PSWinUtil -Times 1 -Exactly -ParameterFilter {
            $LiteralPath -eq 'C:\Program Files\Example\app.exe' -and $Leaf
        }
        Should -Invoke -CommandName Set-WURegistryProperty -ModuleName PSWinUtil -Times 1 -Exactly -ParameterFilter {
            $Path -eq $script:UserRunPath -and
            $Name -eq 'ExampleApp' -and
            $Value -eq '"C:\Program Files\Example\app.exe" --minimized "two words"' -and
            $Type -eq 'String'
        }
    }

    It 'forwards WhatIf to the registry command' {
        Register-WUStartupEntry -Name 'ExampleApp' -FilePath '.\app.exe' -WhatIf

        Should -Invoke -CommandName Set-WURegistryProperty -ModuleName PSWinUtil -Times 1 -Exactly -ParameterFilter {
            $WhatIf
        }
    }

    It 'returns the startup entry with PassThru' {
        $entry = Register-WUStartupEntry -Name 'ExampleApp' -FilePath '.\app.exe' -Scope Machine -PassThru

        $entry.Name | Should -Be 'ExampleApp'
        $entry.Scope | Should -Be 'Machine'
        Should -Invoke -CommandName Get-WUStartupEntry -ModuleName PSWinUtil -Times 1 -Exactly -ParameterFilter {
            $Name -eq 'ExampleApp' -and $Scope -eq 'Machine'
        }
    }

    It 'registers an entry in every selected scope' {
        Register-WUStartupEntry `
            -Name 'ExampleApp' `
            -FilePath '.\app.exe' `
            -Scope User, Machine

        Should -Invoke -CommandName Set-WURegistryProperty -ModuleName PSWinUtil -Times 1 -Exactly -ParameterFilter {
            $Path -eq $script:UserRunPath
        }
        Should -Invoke -CommandName Set-WURegistryProperty -ModuleName PSWinUtil -Times 1 -Exactly -ParameterFilter {
            $Path -eq $script:MachineRunPath
        }
    }

    It 'rejects a command line longer than 260 characters' {
        Mock -CommandName ConvertTo-WUFullPath -ModuleName PSWinUtil -MockWith {
            'C:\' + ('a' * 256)
        }

        {
            Register-WUStartupEntry -Name 'ExampleApp' -FilePath '.\app.exe'
        } | Should -Throw '*260*'
        Should -Invoke -CommandName Set-WURegistryProperty -ModuleName PSWinUtil -Times 0 -Exactly
    }
}

Describe 'Unregister-WUStartupEntry' {
    BeforeEach {
        Mock -CommandName Remove-WURegistryProperty -ModuleName PSWinUtil
    }

    It 'removes only the selected startup entry' {
        Unregister-WUStartupEntry -Name 'ExampleApp' -Scope Machine

        Should -Invoke -CommandName Remove-WURegistryProperty -ModuleName PSWinUtil -Times 1 -Exactly -ParameterFilter {
            $Path -eq $script:MachineRunPath -and $Name -eq 'ExampleApp'
        }
    }

    It 'forwards WhatIf to the registry command' {
        Unregister-WUStartupEntry -Name 'ExampleApp' -WhatIf

        Should -Invoke -CommandName Remove-WURegistryProperty -ModuleName PSWinUtil -Times 1 -Exactly -ParameterFilter {
            $WhatIf
        }
    }

    It 'removes an entry from every selected scope' {
        Unregister-WUStartupEntry `
            -Name 'ExampleApp' `
            -Scope User, Machine

        Should -Invoke -CommandName Remove-WURegistryProperty -ModuleName PSWinUtil -Times 1 -Exactly -ParameterFilter {
            $Path -eq $script:UserRunPath
        }
        Should -Invoke -CommandName Remove-WURegistryProperty -ModuleName PSWinUtil -Times 1 -Exactly -ParameterFilter {
            $Path -eq $script:MachineRunPath
        }
    }
}
