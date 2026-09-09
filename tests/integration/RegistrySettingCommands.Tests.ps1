$runRegistrySettings = $env:PSWINUTIL_RUN_REGISTRY_SETTINGS_INTEGRATION -eq '1'

BeforeAll {
    . (Join-Path -Path $PSScriptRoot -ChildPath '../UnitTestBootstrap.ps1')
    $script:SettingData = Import-PowerShellDataFile (Join-Path $repositoryRoot 'output/PSWinUtil/data/RegistrySettings.psd1')
}

Describe 'Windows setting command state transitions' -Skip:(-not $runRegistrySettings) {
    It 'sets every supported mode for <Setting>' -TestCases @(
        @{ Setting = 'AdvertisingId'; Command = 'Set-WUAdvertisingIdMode'; Parameter = 'Mode'; Options = @('Disabled', 'Default') }
        @{ Setting = 'WindowsUpdateNotificationLevel'; Command = 'Set-WUWindowsUpdateNotificationLevel'; Parameter = 'Level'; Options = @('None', 'RestartWarningsOnly', 'Default') }
    ) {
        param($Setting, $Command, $Parameter, $Options)
        $definition = $script:SettingData.Settings | Where-Object { $_.Name -eq $Setting }
        $saved = @(
            foreach ($property in $definition.Configurations[0].Properties) {
                [pscustomobject]@{ Path = $property.Path; Name = $property.Name; Stored = (Get-WURegistryProperty -Path $property.Path -Name $property.Name) }
            }
        )
        try {
            foreach ($option in $Options) {
                $parameters = @{ $Parameter = $option }
                & $Command @parameters
                (Get-WURegistrySetting -Name $Setting).State | Should -Be $option
            }
            $parameters = @{ $Parameter = $Options[0]; WhatIf = $true }
            & $Command @parameters
            (Get-WURegistrySetting -Name $Setting).State | Should -Be $Options[-1]
        } finally {
            foreach ($property in $saved) {
                if ($null -eq $property.Stored) {
                    Remove-WURegistryProperty -Path $property.Path -Name $property.Name
                } else {
                    Set-WURegistryProperty -Path $property.Path -Name $property.Name -Value $property.Stored.Value -Type $property.Stored.Type
                }
            }
        }
    }

    It 'enables, disables and previews <Setting> through public commands' -TestCases @(
        @{ Setting = 'AppLaunchTracking' }
        @{ Setting = 'AppSuggestions' }
        @{ Setting = 'DarkMode' }
        @{ Setting = 'EdgeFirstRunExperience' }
        @{ Setting = 'FileHistory' }
        @{ Setting = 'LockScreen' }
        @{ Setting = 'LockWorkstation' }
        @{ Setting = 'LongPaths' }
        @{ Setting = 'RequireSignInOnWakeup' }
        @{ Setting = 'SaveZoneInformation' }
        @{ Setting = 'SmartScreenInShell' }
        @{ Setting = 'Uac' }
        @{ Setting = 'WebsiteAccessToLanguageList' }
        @{ Setting = 'Widgets' }
        @{ Setting = 'WindowsHelloForBusiness' }
        @{ Setting = 'WindowsMediaPlayerFirstUseDialogBoxes' }
        @{ Setting = 'WindowsSecurityAllNotifications' }
        @{ Setting = 'WindowsSecurityNonCriticalNotifications' }
    ) {
        param($Setting)
        # The catalog locates values for snapshot/restore only. Expected public
        # transitions are specified by this test, not read from catalog options.
        $definition = $script:SettingData.Settings | Where-Object { $_.Name -eq $Setting }
        $saved = @(
            foreach ($property in $definition.Configurations[0].Properties) {
                [pscustomobject]@{ Path = $property.Path; Name = $property.Name; Stored = (Get-WURegistryProperty -Path $property.Path -Name $property.Name) }
            }
        )
        try {
            & "Enable-WU$Setting"
            (Get-WURegistrySetting -Name $Setting).State | Should -Be 'Enable'
            & "Disable-WU$Setting" -WhatIf
            (Get-WURegistrySetting -Name $Setting).State | Should -Be 'Enable'
            & "Disable-WU$Setting"
            (Get-WURegistrySetting -Name $Setting).State | Should -Be 'Disable'
            & "Disable-WU$Setting"
            (Get-WURegistrySetting -Name $Setting).State | Should -Be 'Disable'
            & "Enable-WU$Setting" -WhatIf
            (Get-WURegistrySetting -Name $Setting).State | Should -Be 'Disable'
        } finally {
            foreach ($property in $saved) {
                if ($null -eq $property.Stored) {
                    Remove-WURegistryProperty -Path $property.Path -Name $property.Name
                } else {
                    Set-WURegistryProperty -Path $property.Path -Name $property.Name -Value $property.Stored.Value -Type $property.Stored.Type
                }
            }
        }
    }
}
