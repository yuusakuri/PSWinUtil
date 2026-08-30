$runKeyboardLayoutIntegration = $env:PSWINUTIL_RUN_KEYBOARD_LAYOUT_INTEGRATION -eq '1'

BeforeAll {
    $repositoryRoot = Split-Path -Path (Split-Path -Path $PSScriptRoot -Parent) -Parent
    $manifestPath = Join-Path -Path $repositoryRoot -ChildPath 'output/PSWinUtil/PSWinUtil.psd1'
    Import-Module -Name $manifestPath -Force -ErrorAction Stop

    $script:Windows11RegistryProperties = @(
        @{
            Path = 'Registry::HKEY_CURRENT_USER\Software\Microsoft\Windows\CurrentVersion\UserProfileEngagement'
            Name = 'ScoobeSystemSettingEnabled'
        }
        @{
            Path = 'Registry::HKEY_CURRENT_USER\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Advanced'
            Name = 'TaskbarAl'
        }
        @{
            Path = 'Registry::HKEY_CURRENT_USER\SOFTWARE\Microsoft\Windows\CurrentVersion\Search'
            Name = 'SearchboxTaskbarMode'
        }
        @{
            Path = 'Registry::HKEY_CURRENT_USER\Software\Classes\CLSID\{86ca1aa0-34aa-4e8b-a509-50c905bae2a2}\InprocServer32'
            Name = ''
        }
        @{
            Path = 'Registry::HKEY_CURRENT_USER\SOFTWARE\Microsoft\IME\15.0\IMJP\Settings'
            Name = 'SpaceInputMode'
        }
        @{
            Path = 'Registry::HKEY_CURRENT_USER\SOFTWARE\Microsoft\IME\15.0\IMJP\Settings'
            Name = 'NumInputMode'
        }
        @{
            Path = 'Registry::HKEY_CURRENT_USER\SOFTWARE\Microsoft\IME\15.0\IMJP\Settings'
            Name = 'AlphabetInputMode'
        }
    )

    $script:KeyboardRegistryProperties = @(
        @{
            Path = 'Registry::HKEY_CURRENT_USER\Keyboard Layout\Substitutes'
            Name = '00000411'
        }
        @{
            Path = 'Registry::HKEY_CURRENT_USER\Keyboard Layout\Preload'
            Name = '1'
        }
        @{
            Path = 'Registry::HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\Keyboard Layouts\00000411'
            Name = 'Layout File'
        }
        @{
            Path = 'Registry::HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Services\i8042prt\Parameters'
            Name = 'LayerDriver JPN'
        }
        @{
            Path = 'Registry::HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Services\i8042prt\Parameters'
            Name = 'OverrideKeyboardIdentifier'
        }
        @{
            Path = 'Registry::HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Services\i8042prt\Parameters'
            Name = 'OverrideKeyboardSubtype'
        }
        @{
            Path = 'Registry::HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Services\i8042prt\Parameters'
            Name = 'OverrideKeyboardType'
        }
    )

    $script:SaveRegistryProperties = {
        param([hashtable[]]$Property)

        @(
            foreach ($inputProperty in $Property) {
                [pscustomobject]@{
                    Path = $inputProperty.Path
                    Name = $inputProperty.Name
                    Value = Get-WURegistryProperty -Path $inputProperty.Path -Name $inputProperty.Name
                }
            }
        )
    }

    $script:RestoreRegistryProperties = {
        param([object[]]$Property)

        foreach ($inputProperty in $Property) {
            if ($null -eq $inputProperty.Value) {
                Remove-WURegistryProperty -Path $inputProperty.Path -Name $inputProperty.Name -Confirm:$false
                continue
            }
            $parameters = @{
                Path = $inputProperty.Path
                Name = $inputProperty.Name
                Value = $inputProperty.Value.Value
                Type = $inputProperty.Value.Type
                Confirm = $false
            }
            Set-WURegistryProperty @parameters
        }
    }
}

Describe 'Windows 11 user setting registry changes' {
    BeforeEach {
        $script:SavedWindows11Properties = & $script:SaveRegistryProperties -Property $script:Windows11RegistryProperties
    }

    AfterEach {
        & $script:RestoreRegistryProperties -Property $script:SavedWindows11Properties
    }

    It 'writes both device setup suggestion states' {
        Enable-WUDeviceSetupSuggestions
        (Get-WURegistryProperty -Path $script:Windows11RegistryProperties[0].Path -Name $script:Windows11RegistryProperties[0].Name).Value |
            Should -Be 1

        Disable-WUDeviceSetupSuggestions
        (Get-WURegistryProperty -Path $script:Windows11RegistryProperties[0].Path -Name $script:Windows11RegistryProperties[0].Name).Value |
            Should -Be 0
    }

    It 'writes both taskbar alignments' {
        Set-WUTaskbarAlignment -Alignment Left
        (Get-WURegistryProperty -Path $script:Windows11RegistryProperties[1].Path -Name $script:Windows11RegistryProperties[1].Name).Value |
            Should -Be 0

        Set-WUTaskbarAlignment -Alignment Center
        (Get-WURegistryProperty -Path $script:Windows11RegistryProperties[1].Path -Name $script:Windows11RegistryProperties[1].Name).Value |
            Should -Be 1
    }

    It 'writes every taskbar search mode' {
        $expectedValues = @{
            Hidden = 0
            Icon = 1
            SearchBox = 2
        }
        foreach ($mode in $expectedValues.Keys) {
            Set-WUTaskbarSearchMode -Mode $mode
            (Get-WURegistryProperty -Path $script:Windows11RegistryProperties[2].Path -Name $script:Windows11RegistryProperties[2].Name).Value |
                Should -Be $expectedValues[$mode]
        }
    }

    It 'sets and removes the classic context menu default value' {
        Enable-WUClassicContextMenu
        $enabledValue = Get-WURegistryProperty -Path $script:Windows11RegistryProperties[3].Path -Name ''
        $enabledValue.Value | Should -Be ''
        $enabledValue.Type | Should -Be 'String'

        Disable-WUClassicContextMenu
        Get-WURegistryProperty -Path $script:Windows11RegistryProperties[3].Path -Name '' |
            Should -BeNullOrEmpty
    }

    It 'writes all Japanese IME half-width values' {
        Set-WUJapaneseImeHalfWidthInput

        foreach ($property in $script:Windows11RegistryProperties[4..6]) {
            $storedProperty = Get-WURegistryProperty -Path $property.Path -Name $property.Name
            $storedProperty.Value | Should -Be 0
            $storedProperty.Type | Should -Be 'DWord'
        }
    }
}

Describe 'Japanese keyboard layout device behavior' {
    BeforeEach {
        if (-not $runKeyboardLayoutIntegration) {
            return
        }
        $script:SavedKeyboardProperties = & $script:SaveRegistryProperties -Property $script:KeyboardRegistryProperties
        $script:SavedLanguageList = Get-WinUserLanguageList
    }

    AfterEach {
        if (-not $runKeyboardLayoutIntegration) {
            return
        }
        & $script:RestoreRegistryProperties -Property $script:SavedKeyboardProperties
        Set-WinUserLanguageList -LanguageList $script:SavedLanguageList -Force
    }

    It 'writes and restores US and Japanese keyboard values' -Skip:(-not $runKeyboardLayoutIntegration) {
        Set-WUJapaneseKeyboardLayout -Layout US
        (Get-WURegistryProperty -Path $script:KeyboardRegistryProperties[2].Path -Name 'Layout File').Value |
            Should -Be 'KBDUS.DLL'
        (Get-WURegistryProperty -Path $script:KeyboardRegistryProperties[3].Path -Name 'LayerDriver JPN').Value |
            Should -Be 'kbd101.dll'

        Set-WUJapaneseKeyboardLayout -Layout Japanese
        (Get-WURegistryProperty -Path $script:KeyboardRegistryProperties[2].Path -Name 'Layout File').Value |
            Should -Be 'KBDJPN.DLL'
        (Get-WURegistryProperty -Path $script:KeyboardRegistryProperties[3].Path -Name 'LayerDriver JPN').Value |
            Should -Be 'kbd106.dll'
    }
}
