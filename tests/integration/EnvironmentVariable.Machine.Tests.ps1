$runMachineIntegration = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole(
    [Security.Principal.WindowsBuiltInRole]::Administrator
)

Describe 'Machine environment variable integration' -Skip:(-not $runMachineIntegration) {
    BeforeAll {
        $repositoryRoot = Split-Path -Path (Split-Path -Path $PSScriptRoot -Parent) -Parent
        $manifestPath = Join-Path -Path $repositoryRoot -ChildPath 'output/PSWinUtil/PSWinUtil.psd1'
        Import-Module -Name $manifestPath -Force -ErrorAction Stop

        $script:EnvironmentTarget = [System.EnvironmentVariableTarget]::Machine
        $script:EnvironmentName = 'PSWINUTIL_TEST_' + [guid]::NewGuid().ToString('N')
        $script:OriginalValue = [System.Environment]::GetEnvironmentVariable(
            $script:EnvironmentName,
            $script:EnvironmentTarget
        )
    }

    AfterEach {
        $registryKey = [Microsoft.Win32.Registry]::LocalMachine.OpenSubKey('SYSTEM\CurrentControlSet\Control\Session Manager\Environment', $true)
        try {
            $registryKey.DeleteValue($script:EnvironmentName, $false)
        } finally {
            $registryKey.Dispose()
        }
        [PSWinUtil.EnvironmentChangeNotification]::Broadcast() | Out-Null
    }

    It 'sets a Machine environment variable' {
        Set-WUEnvironmentVariable -Name $script:EnvironmentName -Value 'machine value' -Scope Machine

        [System.Environment]::GetEnvironmentVariable(
            $script:EnvironmentName,
            $script:EnvironmentTarget
        ) | Should -Be 'machine value'
    }

    It 'gets a Machine environment variable' {
        Set-WUEnvironmentVariable -Name $script:EnvironmentName -Value 'machine value' -Scope Machine

        Get-WUEnvironmentVariable -Name $script:EnvironmentName -Scope Machine |
            Should -Be 'machine value'
    }

    It 'removes a Machine environment variable' {
        Set-WUEnvironmentVariable -Name $script:EnvironmentName -Value 'value to remove' -Scope Machine

        Remove-WUEnvironmentVariable -Name $script:EnvironmentName -Scope Machine

        $actualValue = [System.Environment]::GetEnvironmentVariable(
            $script:EnvironmentName,
            $script:EnvironmentTarget
        )
        ($null -eq $actualValue) | Should -BeTrue
    }

    It 'removes a Machine environment variable with a null value' {
        Set-WUEnvironmentVariable -Name $script:EnvironmentName -Value 'value to remove' -Scope Machine

        Set-WUEnvironmentVariable -Name $script:EnvironmentName -Value $null -Scope Machine

        $actualValue = [System.Environment]::GetEnvironmentVariable(
            $script:EnvironmentName,
            $script:EnvironmentTarget
        )
        ($null -eq $actualValue) | Should -BeTrue
    }
}
