BeforeAll {
    $repositoryRoot = Split-Path -Path (Split-Path -Path $PSScriptRoot -Parent) -Parent
    $manifestPath = Join-Path -Path $repositoryRoot -ChildPath 'output/PSWinUtil/PSWinUtil.psd1'
    Import-Module -Name $manifestPath -Force -ErrorAction Stop

    $script:UserRunPath = 'Registry::HKEY_CURRENT_USER\Software\Microsoft\Windows\CurrentVersion\Run'
    $script:MachineRunPath = 'Registry::HKEY_LOCAL_MACHINE\Software\Microsoft\Windows\CurrentVersion\Run'
    $script:IsAdministrator = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole(
        [Security.Principal.WindowsBuiltInRole]::Administrator
    )
}

Describe 'Startup entry commands' {
    BeforeEach {
        $script:EntryName = 'PSWinUtilTest_' + [guid]::NewGuid().ToString('N')
        $script:ExecutablePath = Join-Path -Path $env:WINDIR -ChildPath 'System32\notepad.exe'
    }

    AfterEach {
        foreach ($registryPath in @($script:UserRunPath, $script:MachineRunPath)) {
            if (-not (Test-Path -LiteralPath $registryPath -PathType Container)) {
                continue
            }
            $registryKey = Get-Item -LiteralPath $registryPath
            if ($script:EntryName -in @($registryKey.GetValueNames())) {
                Remove-ItemProperty -LiteralPath $registryPath -Name $script:EntryName -Force
            }
        }
    }

    It 'registers, gets, and unregisters a user startup entry' {
        $entry = Register-WUStartupEntry -Name $script:EntryName -FilePath $script:ExecutablePath -ArgumentList '--test', 'two words' -PassThru

        $entry.Name | Should -Be $script:EntryName
        $entry.Scope | Should -Be 'User'
        $entry.CommandLine | Should -Match [regex]::Escape('notepad.exe" --test "two words"')

        Unregister-WUStartupEntry -Name $script:EntryName
        Get-WUStartupEntry -Name $script:EntryName -Scope User | Should -BeNullOrEmpty
    }

    It 'does not register a user startup entry with WhatIf' {
        Register-WUStartupEntry -Name $script:EntryName -FilePath $script:ExecutablePath -WhatIf

        Get-WUStartupEntry -Name $script:EntryName -Scope User | Should -BeNullOrEmpty
    }

    It 'registers and unregisters a machine startup entry' -Skip:(-not $script:IsAdministrator) {
        Register-WUStartupEntry -Name $script:EntryName -FilePath $script:ExecutablePath -Scope Machine

        $entry = Get-WUStartupEntry -Name $script:EntryName -Scope Machine
        $entry.Name | Should -Be $script:EntryName
        $entry.Scope | Should -Be 'Machine'

        Unregister-WUStartupEntry -Name $script:EntryName -Scope Machine
        Get-WUStartupEntry -Name $script:EntryName -Scope Machine | Should -BeNullOrEmpty
    }
}
