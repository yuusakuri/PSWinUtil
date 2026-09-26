Describe 'User environment variable integration' {
    BeforeAll {
        $repositoryRoot = Split-Path -Path (Split-Path -Path $PSScriptRoot -Parent) -Parent
        $manifestPath = Join-Path -Path $repositoryRoot -ChildPath 'output/PSWinUtil/PSWinUtil.psd1'
        Import-Module -Name $manifestPath -Force -ErrorAction Stop

        $script:EnvironmentTarget = [System.EnvironmentVariableTarget]::User
        $script:EnvironmentName = 'PSWINUTIL_TEST_' + [guid]::NewGuid().ToString('N')
        $script:ReferenceName = $script:EnvironmentName + '_ROOT'
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
            $registryKey.DeleteValue($script:ReferenceName, $false)
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
        Get-WUEnvironmentVariable -Name $script:EnvironmentName -Scope User | Should -Be $expected
        Get-WUEnvironmentVariable -Name $script:EnvironmentName -Scope User -NoExpand | Should -Be '%USERPROFILE%\bin'
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

    It 'stores references as expandable values and returns the unexpanded saved state' {
        $result = @(Set-WUEnvironmentVariable -Name $script:EnvironmentName -Value '%USERPROFILE%\bin' -Scope User -PassThru)
        $result | Should -HaveCount 1
        ($result | Select-Object -First 1).Value | Should -Be '%USERPROFILE%\bin'
        $registryKey = [Microsoft.Win32.Registry]::CurrentUser.OpenSubKey('Environment')
        try {
            $registryKey.GetValue($script:EnvironmentName, $null, [Microsoft.Win32.RegistryValueOptions]::DoNotExpandEnvironmentNames) | Should -Be '%USERPROFILE%\bin'
            $registryKey.GetValueKind($script:EnvironmentName) | Should -Be ([Microsoft.Win32.RegistryValueKind]::ExpandString)
        } finally {
            $registryKey.Dispose()
        }
        [Environment]::GetEnvironmentVariable($script:EnvironmentName, 'Process') | Should -BeNullOrEmpty
    }

    It 'replaces an expandable value with a plain <Value> value' -ForEach @(
        @{ Value = '100%' }
        @{ Value = 'C:\Tools' }
    ) {
        @(
            [pscustomobject]@{ Name = $script:EnvironmentName; Value = '%USERPROFILE%\bin' }
            [pscustomobject]@{ Name = $script:EnvironmentName; Value = $Value }
        ) | Set-WUEnvironmentVariable -Scope User

        Get-WUEnvironmentVariable -Name $script:EnvironmentName -Scope User | Should -Be $Value
        $registryKey = [Microsoft.Win32.Registry]::CurrentUser.OpenSubKey('Environment')
        try {
            $registryKey.GetValueKind($script:EnvironmentName) | Should -Be ([Microsoft.Win32.RegistryValueKind]::String)
        } finally {
            $registryKey.Dispose()
        }
    }

    It 'expands a persistent reference using the saved user value instead of a stale process value' {
        [Environment]::SetEnvironmentVariable($script:ReferenceName, 'C:\StaleProcess', 'Process')
        $reference = "%$($script:ReferenceName)%\bin"
        @(
            [pscustomobject]@{ Name = $script:ReferenceName; Value = 'C:\CurrentUser' }
            [pscustomobject]@{ Name = $script:EnvironmentName; Value = $reference }
        ) | Set-WUEnvironmentVariable -Scope User

        Get-WUEnvironmentVariable -Name $script:EnvironmentName -Scope User | Should -Be 'C:\CurrentUser\bin'
        Get-WUEnvironmentVariable -Name $script:EnvironmentName -Scope User -NoExpand | Should -Be $reference
        Update-WUProcessEnvironment
        [Environment]::GetEnvironmentVariable($script:EnvironmentName, 'Process') | Should -Be 'C:\CurrentUser\bin'
    }

    It 'removes multiple variables from Process and User with <InputKind> input' -ForEach @(
        @{ InputKind = 'array' }
        @{ InputKind = 'pipeline' }
    ) {
        $names = @($script:EnvironmentName, $script:ReferenceName)
        $names | ForEach-Object { [pscustomobject]@{ Name = $_; Value = 'value to remove' } } |
            Set-WUEnvironmentVariable -Scope Process, User

        if ($InputKind -eq 'array') {
            Remove-WUEnvironmentVariable -Name $names -Scope Process, User
        } else {
            $names | Remove-WUEnvironmentVariable -Scope Process, User
        }
        foreach ($name in $names) {
            foreach ($scope in @('Process', 'User')) {
                [Environment]::GetEnvironmentVariable($name, $scope) | Should -BeNullOrEmpty
            }
        }
    }

    It 'previews persistent removal of multiple variables' {
        $names = @($script:EnvironmentName, $script:ReferenceName)
        $names | ForEach-Object { [pscustomobject]@{ Name = $_; Value = 'saved value' } } |
            Set-WUEnvironmentVariable -Scope User

        $names | Remove-WUEnvironmentVariable -Scope User -WhatIf

        foreach ($name in $names) {
            [Environment]::GetEnvironmentVariable($name, 'User') | Should -Be 'saved value'
        }
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
        ($result | Select-Object -First 1).Value | Should -Be 'first value'
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
