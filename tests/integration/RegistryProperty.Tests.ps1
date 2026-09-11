BeforeAll {
    $repositoryRoot = Split-Path -Path (Split-Path -Path $PSScriptRoot -Parent) -Parent
    $manifestPath = Join-Path -Path $repositoryRoot -ChildPath 'output/PSWinUtil/PSWinUtil.psd1'
    Import-Module -Name $manifestPath -Force -ErrorAction Stop

    $script:RegistryTestPath = 'Registry::HKEY_CURRENT_USER\Software\PSWinUtilTest_' +
    [guid]::NewGuid().ToString('N')
}

Describe 'Registry property commands' {
    It 'round-trips a 64-bit integer beyond the 32-bit range' {
        Set-WURegistryProperty -Path $script:RegistryTestPath -Name 'Large' -Type QWord -Value ([long]4294967296)
        $stored = Get-WURegistryProperty -Path $script:RegistryTestPath -Name 'Large'
        $stored.Type | Should -Be 'QWord'
        $stored.Value | Should -Be ([long]4294967296)
    }

    It 'preserves unexpanded environment references in ExpandString values' {
        Set-WURegistryProperty -Path $script:RegistryTestPath -Name 'Location' -Type ExpandString -Value '%TEMP%\PSWinUtil'
        $stored = Get-WURegistryProperty -Path $script:RegistryTestPath -Name 'Location'
        $stored.Type | Should -Be 'ExpandString'
        $stored.Value | Should -Be '%TEMP%\PSWinUtil'
    }

    It 'preserves typed array values across repeated writes and updates' -TestCases @(
        @{ Type = 'Binary'; First = [byte[]]@(1, 2); Second = [byte[]]@(2, 1) }
        @{ Type = 'MultiString'; First = @('first', 'second'); Second = @('second', 'first') }
    ) {
        param($Type, $First, $Second)
        Set-WURegistryProperty -Path $script:RegistryTestPath -Name Array -Value $First -Type $Type
        Set-WURegistryProperty -Path $script:RegistryTestPath -Name Array -Value $First -Type $Type
        $stored = Get-WURegistryProperty -Path $script:RegistryTestPath -Name Array
        $stored.Type | Should -Be $Type
        $stored.Value | Should -Be $First
        Set-WURegistryProperty -Path $script:RegistryTestPath -Name Array -Value $Second -Type $Type
        (Get-WURegistryProperty -Path $script:RegistryTestPath -Name Array).Value | Should -Be $Second
    }

    AfterEach {
        if (Test-Path -LiteralPath $script:RegistryTestPath) {
            Remove-Item -LiteralPath $script:RegistryTestPath -Recurse -Force
        }
    }

    It 'creates and gets a registry property with its type' {
        $storedProperty = Set-WURegistryProperty `
            -Path $script:RegistryTestPath `
            -Name 'Enabled' `
            -Value 1 `
            -Type DWord `
            -PassThru

        $storedProperty.Value | Should -Be 1
        $storedProperty.Type | Should -Be 'DWord'
        $storedProperty.PSObject.TypeNames | Should -Contain 'PSWinUtil.RegistryProperty'

        $readProperty = Get-WURegistryProperty `
            -Path $script:RegistryTestPath `
            -Name 'Enabled'
        $readProperty.Value | Should -Be 1
        $readProperty.Type | Should -Be 'DWord'
    }

    It 'updates a registry property value and type' {
        Set-WURegistryProperty `
            -Path $script:RegistryTestPath `
            -Name 'Setting' `
            -Value 'old' `
            -Type String

        Set-WURegistryProperty `
            -Path $script:RegistryTestPath `
            -Name 'Setting' `
            -Value 2 `
            -Type DWord

        $storedProperty = Get-WURegistryProperty `
            -Path $script:RegistryTestPath `
            -Name 'Setting'
        $storedProperty.Value | Should -Be 2
        $storedProperty.Type | Should -Be 'DWord'
    }

    It 'sets, gets, and removes the default registry value' {
        Set-WURegistryProperty `
            -Path $script:RegistryTestPath `
            -Name '' `
            -Value 'default text' `
            -Type String

        $storedProperty = Get-WURegistryProperty `
            -Path $script:RegistryTestPath `
            -Name ''
        $storedProperty.Name | Should -Be ''
        $storedProperty.Value | Should -Be 'default text'
        $storedProperty.Type | Should -Be 'String'

        Remove-WURegistryProperty `
            -Path $script:RegistryTestPath `
            -Name ''

        Get-WURegistryProperty `
            -Path $script:RegistryTestPath `
            -Name '' | Should -BeNullOrEmpty
    }

    It 'preserves MultiString values' {
        Set-WURegistryProperty `
            -Path $script:RegistryTestPath `
            -Name 'Items' `
            -Value @('first', 'second') `
            -Type MultiString

        $storedProperty = Get-WURegistryProperty `
            -Path $script:RegistryTestPath `
            -Name 'Items'
        @($storedProperty.Value).Count | Should -Be 2
        $storedProperty.Value[0] | Should -Be 'first'
        $storedProperty.Value[1] | Should -Be 'second'
        $storedProperty.Type | Should -Be 'MultiString'
    }

    It 'removes a registry property and preserves its key' {
        Set-WURegistryProperty `
            -Path $script:RegistryTestPath `
            -Name 'Setting' `
            -Value 1 `
            -Type DWord

        Remove-WURegistryProperty `
            -Path $script:RegistryTestPath `
            -Name 'Setting'

        Get-WURegistryProperty `
            -Path $script:RegistryTestPath `
            -Name 'Setting' | Should -BeNullOrEmpty
        Test-Path -LiteralPath $script:RegistryTestPath -PathType Container |
            Should -BeTrue
    }

    It 'does not create a registry key with WhatIf' {
        Set-WURegistryProperty `
            -Path $script:RegistryTestPath `
            -Name 'Setting' `
            -Value 1 `
            -Type DWord `
            -WhatIf

        Test-Path -LiteralPath $script:RegistryTestPath | Should -BeFalse
    }

    It 'does not remove a registry property with WhatIf' {
        Set-WURegistryProperty `
            -Path $script:RegistryTestPath `
            -Name 'Setting' `
            -Value 1 `
            -Type DWord

        Remove-WURegistryProperty `
            -Path $script:RegistryTestPath `
            -Name 'Setting' `
            -WhatIf

        Get-WURegistryProperty `
            -Path $script:RegistryTestPath `
            -Name 'Setting' | Should -Not -BeNullOrEmpty
    }

    It 'does nothing for a missing key or property' {
        Get-WURegistryProperty `
            -Path $script:RegistryTestPath `
            -Name 'Missing' | Should -BeNullOrEmpty

        {
            Remove-WURegistryProperty `
                -Path $script:RegistryTestPath `
                -Name 'Missing'
        } | Should -Not -Throw
    }
}
