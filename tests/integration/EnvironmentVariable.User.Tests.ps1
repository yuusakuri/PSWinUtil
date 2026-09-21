Describe 'User environment variable integration' {
    BeforeAll {
        $repositoryRoot = Split-Path -Path (Split-Path -Path $PSScriptRoot -Parent) -Parent
        $manifestPath = Join-Path -Path $repositoryRoot -ChildPath 'output/PSWinUtil/PSWinUtil.psd1'
        Import-Module -Name $manifestPath -Force -ErrorAction Stop

        $script:EnvironmentTarget = [System.EnvironmentVariableTarget]::User
        $script:EnvironmentName = 'PSWINUTIL_TEST_' + [guid]::NewGuid().ToString('N')
        $script:OriginalValue = [System.Environment]::GetEnvironmentVariable(
            $script:EnvironmentName,
            $script:EnvironmentTarget
        )
    }

    BeforeEach {
        $script:OriginalProcessEnvironment = [Environment]::GetEnvironmentVariables('Process')
    }

    AfterEach {
        $registryKey = [Microsoft.Win32.Registry]::CurrentUser.OpenSubKey('Environment', $true)
        try {
            $registryKey.DeleteValue($script:EnvironmentName, $false)
        } finally {
            $registryKey.Dispose()
        }
        [PSWinUtil.EnvironmentChangeNotification]::Broadcast() | Out-Null
        foreach ($name in [Environment]::GetEnvironmentVariables('Process').Keys) {
            if (-not $script:OriginalProcessEnvironment.Contains($name)) {
                [Environment]::SetEnvironmentVariable($name, $null, 'Process')
            }
        }
        foreach ($name in $script:OriginalProcessEnvironment.Keys) {
            [Environment]::SetEnvironmentVariable($name, $script:OriginalProcessEnvironment[$name], 'Process')
        }
    }

    It 'reloads a <Kind> user value using the Windows user environment block' -ForEach @(
        @{ Kind = 'ExpandString'; Expand = $true }
        @{ Kind = 'String'; Expand = $false }
    ) {
        $registryKey = [Microsoft.Win32.Registry]::CurrentUser.OpenSubKey('Environment', $true)
        try {
            $registryKey.SetValue($script:EnvironmentName, '%USERPROFILE%\bin', [Microsoft.Win32.RegistryValueKind]$Kind)
        } finally {
            $registryKey.Dispose()
        }
        [PSWinUtil.EnvironmentChangeNotification]::Broadcast() | Out-Null
        $expected = if ($Expand) { Join-Path $env:USERPROFILE 'bin' } else { '%USERPROFILE%\bin' }
        Update-WUProcessEnvironment
        [Environment]::GetEnvironmentVariable($script:EnvironmentName, 'Process') | Should -Be $expected
    }

    It 'sets a User environment variable' {
        Set-WUEnvironmentVariable -Name $script:EnvironmentName -Value 'user value' -Scope User

        [System.Environment]::GetEnvironmentVariable(
            $script:EnvironmentName,
            $script:EnvironmentTarget
        ) | Should -Be 'user value'
    }

    It 'stores literal percent references as REG_SZ and returns only the saved state' {
        $result = @(Set-WUEnvironmentVariable -Name $script:EnvironmentName -Value '%USERPROFILE%\bin' -Scope User -PassThru)
        $result | Should -HaveCount 1
        $result[0].Value | Should -Be '%USERPROFILE%\bin'
        $registryKey = [Microsoft.Win32.Registry]::CurrentUser.OpenSubKey('Environment')
        try {
            $registryKey.GetValue($script:EnvironmentName) | Should -Be '%USERPROFILE%\bin'
            $registryKey.GetValueKind($script:EnvironmentName) | Should -Be ([Microsoft.Win32.RegistryValueKind]::String)
        } finally {
            $registryKey.Dispose()
        }
        [Environment]::GetEnvironmentVariable($script:EnvironmentName, 'Process') | Should -BeNullOrEmpty
    }

    It 'does not write persistent state with WhatIf' {
        Set-WUEnvironmentVariable -Name $script:EnvironmentName -Value 'preview' -Scope User -WhatIf
        [Environment]::GetEnvironmentVariable($script:EnvironmentName, 'User') | Should -BeNullOrEmpty
    }

    It 'saves pipeline values without emitting notification results' {
        $settings = @(
            [pscustomobject]@{ Name = $script:EnvironmentName; Value = 'first value' }
            [pscustomobject]@{ Name = $script:EnvironmentName; Value = 'last value' }
        )
        $result = @($settings | Set-WUEnvironmentVariable -Scope User -PassThru)
        $result | Should -HaveCount 2
        $result[0].Value | Should -Be 'first value'
        $result[1].Value | Should -Be 'last value'
        [Environment]::GetEnvironmentVariable($script:EnvironmentName, 'User') | Should -Be 'last value'
    }

    It 'removes a User environment variable with an empty value' {
        Set-WUEnvironmentVariable -Name $script:EnvironmentName -Value 'value to remove' -Scope User
        Set-WUEnvironmentVariable -Name $script:EnvironmentName -Value '' -Scope User
        [Environment]::GetEnvironmentVariable($script:EnvironmentName, 'User') | Should -BeNullOrEmpty
    }

    It 'gets a User environment variable' {
        Set-WUEnvironmentVariable -Name $script:EnvironmentName -Value 'user value' -Scope User

        Get-WUEnvironmentVariable -Name $script:EnvironmentName -Scope User |
            Should -Be 'user value'
    }

    It 'removes a User environment variable' {
        Set-WUEnvironmentVariable -Name $script:EnvironmentName -Value 'value to remove' -Scope User

        Remove-WUEnvironmentVariable -Name $script:EnvironmentName -Scope User

        $actualValue = [System.Environment]::GetEnvironmentVariable(
            $script:EnvironmentName,
            $script:EnvironmentTarget
        )
        ($null -eq $actualValue) | Should -BeTrue
    }

    It 'removes a User environment variable with a null value' {
        Set-WUEnvironmentVariable -Name $script:EnvironmentName -Value 'value to remove' -Scope User

        Set-WUEnvironmentVariable -Name $script:EnvironmentName -Value $null -Scope User

        $actualValue = [System.Environment]::GetEnvironmentVariable(
            $script:EnvironmentName,
            $script:EnvironmentTarget
        )
        ($null -eq $actualValue) | Should -BeTrue
    }
}
