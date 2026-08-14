BeforeAll {
    $repositoryRoot = Split-Path -Path (Split-Path -Path $PSScriptRoot -Parent) -Parent
    $manifestPath = Join-Path -Path $repositoryRoot -ChildPath 'output/PSWinUtil/PSWinUtil.psd1'
    Import-Module -Name $manifestPath -Force -ErrorAction Stop
}

Describe 'Set-WUEnvironmentVariable' {
    BeforeEach {
        Mock -CommandName Set-WUEnvironmentVariableValue -ModuleName PSWinUtil -MockWith {}
    }

    It 'sets a named variable in the selected scope' {
        Set-WUEnvironmentVariable -Name 'PSWINUTIL_TEST_NAME' -Value 'value' -Scope User

        Should -Invoke -CommandName Set-WUEnvironmentVariableValue -ModuleName PSWinUtil -Times 1 -Exactly -ParameterFilter {
            $Name -eq 'PSWINUTIL_TEST_NAME' -and
            $Value -eq 'value' -and
            $Scope -eq 'User'
        }
    }

    It 'does not set a named variable with WhatIf' {
        Set-WUEnvironmentVariable -Name 'PSWINUTIL_TEST_NAME' -Value 'value' -WhatIf

        Should -Invoke -CommandName Set-WUEnvironmentVariableValue -ModuleName PSWinUtil -Times 0 -Exactly
    }

    It 'reads string values from a PowerShell data file Hashtable' {
        $environmentFile = Join-Path -Path $TestDrive -ChildPath 'environment.psd1'
        [System.IO.File]::WriteAllText(
            $environmentFile,
            "@{`n    FIRST_NAME = 'first value'`n    SECOND_NAME = 'second=value'`n}`n",
            [System.Text.UTF8Encoding]::new($false)
        )

        Set-WUEnvironmentVariable -Path $environmentFile -Scope User

        Should -Invoke -CommandName Set-WUEnvironmentVariableValue -ModuleName PSWinUtil -Times 1 -Exactly -ParameterFilter {
            $Name -eq 'FIRST_NAME' -and $Value -eq 'first value' -and $Scope -eq 'User'
        }
        Should -Invoke -CommandName Set-WUEnvironmentVariableValue -ModuleName PSWinUtil -Times 1 -Exactly -ParameterFilter {
            $Name -eq 'SECOND_NAME' -and $Value -eq 'second=value' -and $Scope -eq 'User'
        }
    }

    It 'rejects a data file without a Hashtable root' {
        $environmentFile = Join-Path -Path $TestDrive -ChildPath 'invalid-root.psd1'
        [System.IO.File]::WriteAllText(
            $environmentFile,
            "@{}`n",
            [System.Text.UTF8Encoding]::new($false)
        )
        Mock -CommandName Import-PowerShellDataFile -ModuleName PSWinUtil -MockWith {
            'not a Hashtable'
        }
        $reportedErrors = @()

        Set-WUEnvironmentVariable -Path $environmentFile -ErrorAction SilentlyContinue -ErrorVariable +reportedErrors

        $reportedErrors.Count | Should -Be 1
        $reportedErrors[0].FullyQualifiedErrorId | Should -Match '^InvalidEnvironmentDataFileRoot'
        Should -Invoke -CommandName Set-WUEnvironmentVariableValue -ModuleName PSWinUtil -Times 0 -Exactly
    }

    It 'rejects a data file with an invalid environment variable name' {
        $environmentFile = Join-Path -Path $TestDrive -ChildPath 'invalid-name.psd1'
        [System.IO.File]::WriteAllText(
            $environmentFile,
            "@{`n    VALID_NAME = 'valid value'`n    'INVALID=NAME' = 'invalid value'`n}`n",
            [System.Text.UTF8Encoding]::new($false)
        )
        $reportedErrors = @()

        Set-WUEnvironmentVariable -Path $environmentFile -ErrorAction SilentlyContinue -ErrorVariable +reportedErrors

        $reportedErrors.Count | Should -Be 1
        $reportedErrors[0].FullyQualifiedErrorId | Should -Match '^InvalidEnvironmentDataFileEntry'
        Should -Invoke -CommandName Set-WUEnvironmentVariableValue -ModuleName PSWinUtil -Times 0 -Exactly
    }

    It 'rejects a data file with a non-string value' {
        $environmentFile = Join-Path -Path $TestDrive -ChildPath 'invalid-value.psd1'
        [System.IO.File]::WriteAllText(
            $environmentFile,
            "@{`n    VALID_NAME = 'valid value'`n    INVALID_VALUE = 123`n}`n",
            [System.Text.UTF8Encoding]::new($false)
        )
        $reportedErrors = @()

        Set-WUEnvironmentVariable -Path $environmentFile -ErrorAction SilentlyContinue -ErrorVariable +reportedErrors

        $reportedErrors.Count | Should -Be 1
        $reportedErrors[0].FullyQualifiedErrorId | Should -Match '^InvalidEnvironmentDataFileEntry'
        Should -Invoke -CommandName Set-WUEnvironmentVariableValue -ModuleName PSWinUtil -Times 0 -Exactly
    }

    It 'rejects a file that does not use the psd1 extension' {
        {
            Set-WUEnvironmentVariable -Path (Join-Path -Path $TestDrive -ChildPath 'environment.env')
        } | Should -Throw
    }

    It 'does not set data file variables with WhatIf' {
        $environmentFile = Join-Path -Path $TestDrive -ChildPath 'what-if.psd1'
        [System.IO.File]::WriteAllText(
            $environmentFile,
            "@{`n    FIRST_NAME = 'first value'`n}`n",
            [System.Text.UTF8Encoding]::new($false)
        )

        Set-WUEnvironmentVariable -Path $environmentFile -WhatIf

        Should -Invoke -CommandName Set-WUEnvironmentVariableValue -ModuleName PSWinUtil -Times 0 -Exactly
    }

    It 'rejects an invalid environment variable name' {
        {
            Set-WUEnvironmentVariable -Name 'INVALID=NAME' -Value 'value'
        } | Should -Throw
    }
}

Describe 'Remove-WUEnvironmentVariable' {
    BeforeEach {
        Mock -CommandName Get-WUEnvironmentVariableValue -ModuleName PSWinUtil -MockWith { $null }
        Mock -CommandName Set-WUEnvironmentVariableValue -ModuleName PSWinUtil -MockWith {}
    }

    It 'does nothing when the variable does not exist' {
        Remove-WUEnvironmentVariable -Name 'PSWINUTIL_TEST_NAME' -Scope User

        Should -Invoke -CommandName Set-WUEnvironmentVariableValue -ModuleName PSWinUtil -Times 0 -Exactly
    }

    It 'removes an existing variable from the selected scope' {
        Mock -CommandName Get-WUEnvironmentVariableValue -ModuleName PSWinUtil -MockWith { 'value' }

        Remove-WUEnvironmentVariable -Name 'PSWINUTIL_TEST_NAME' -Scope Machine

        Should -Invoke -CommandName Set-WUEnvironmentVariableValue -ModuleName PSWinUtil -Times 1 -Exactly -ParameterFilter {
            $Name -eq 'PSWINUTIL_TEST_NAME' -and $Remove -and $Scope -eq 'Machine'
        }
    }

    It 'does not remove an existing variable with WhatIf' {
        Mock -CommandName Get-WUEnvironmentVariableValue -ModuleName PSWinUtil -MockWith { 'value' }

        Remove-WUEnvironmentVariable -Name 'PSWINUTIL_TEST_NAME' -WhatIf

        Should -Invoke -CommandName Set-WUEnvironmentVariableValue -ModuleName PSWinUtil -Times 0 -Exactly
    }
}
