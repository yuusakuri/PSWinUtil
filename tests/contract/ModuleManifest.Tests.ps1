BeforeAll {
    $repositoryRoot = Split-Path -Path (Split-Path -Path $PSScriptRoot -Parent) -Parent
    $script:ManifestPath = Join-Path -Path $repositoryRoot -ChildPath 'output/PSWinUtil/PSWinUtil.psd1'
}

Describe 'Built module manifest' {
    It 'is valid' {
        { Test-ModuleManifest -Path $script:ManifestPath -ErrorAction Stop } | Should -Not -Throw
    }

    It 'targets Windows PowerShell 5.1 Desktop' {
        $manifest = Import-PowerShellDataFile -Path $script:ManifestPath

        $manifest.PowerShellVersion | Should -Be '5.1'
        $manifest.CompatiblePSEditions | Should -Contain 'Desktop'
    }

    It 'has no runtime module dependency' {
        $manifest = Import-PowerShellDataFile -Path $script:ManifestPath

        @($manifest.RequiredModules).Count | Should -Be 0
    }

    It 'exports every implemented setup command' {
        Import-Module -Name $script:ManifestPath -Force -ErrorAction Stop
        $exportedCommands = @(
            (Get-Module -Name 'PSWinUtil' -ErrorAction Stop).ExportedFunctions.Keys
        )
        $expectedCommands = @(
            'Get-WURegistryProperty'
            'Set-WURegistryProperty'
            'Remove-WURegistryProperty'
            'Get-WURegistrySetting'
            'Set-WUAdvertisingIdMode'
            'Enable-WUAppLaunchTracking'
            'Disable-WUAppLaunchTracking'
            'Enable-WUAppSuggestions'
            'Disable-WUAppSuggestions'
            'Enable-WUDarkMode'
            'Disable-WUDarkMode'
            'Enable-WUEdgeFirstRunExperience'
            'Disable-WUEdgeFirstRunExperience'
            'Enable-WUFileHistory'
            'Disable-WUFileHistory'
            'Enable-WULockScreen'
            'Disable-WULockScreen'
            'Enable-WULockWorkstation'
            'Disable-WULockWorkstation'
            'Enable-WULongPaths'
            'Disable-WULongPaths'
            'Enable-WUWidgets'
            'Disable-WUWidgets'
            'Enable-WURequireSignInOnWakeup'
            'Disable-WURequireSignInOnWakeup'
            'Enable-WUSaveZoneInformation'
            'Disable-WUSaveZoneInformation'
            'Enable-WUSmartScreenInShell'
            'Disable-WUSmartScreenInShell'
            'Enable-WUUac'
            'Disable-WUUac'
            'Enable-WUWebsiteAccessToLanguageList'
            'Disable-WUWebsiteAccessToLanguageList'
            'Enable-WUWindowsHelloForBusiness'
            'Disable-WUWindowsHelloForBusiness'
            'Enable-WUWindowsMediaPlayerFirstUseDialogBoxes'
            'Disable-WUWindowsMediaPlayerFirstUseDialogBoxes'
            'Enable-WUWindowsSecurityAllNotifications'
            'Disable-WUWindowsSecurityAllNotifications'
            'Enable-WUWindowsSecurityNonCriticalNotifications'
            'Disable-WUWindowsSecurityNonCriticalNotifications'
            'Set-WUWindowsUpdateNotificationLevel'
            'Get-WUStartupEntry'
            'Register-WUStartupEntry'
            'Unregister-WUStartupEntry'
            'Get-WUWindowsAutoLogon'
            'Enable-WUWindowsAutoLogon'
            'Disable-WUWindowsAutoLogon'
            'Get-WUKeyboardRemapping'
            'Set-WUKeyboardRemapping'
            'Remove-WUKeyboardRemapping'
        )

        foreach ($expectedCommand in $expectedCommands) {
            $exportedCommands | Should -Contain $expectedCommand
        }
    }

    It 'contains the public structured output type names' {
        $modulePath = Join-Path -Path (Split-Path -Path $script:ManifestPath -Parent) -ChildPath 'PSWinUtil.psm1'
        $moduleText = [System.IO.File]::ReadAllText($modulePath)

        $moduleText | Should -Match "PSTypeName = 'PSWinUtil.RegistryProperty'"
        $moduleText | Should -Match "PSTypeName = 'PSWinUtil.RegistrySetting'"
        $moduleText | Should -Match "PSTypeName = 'PSWinUtil.StartupEntry'"
        $moduleText | Should -Match "PSTypeName = 'PSWinUtil.WindowsAutoLogon'"
        $moduleText | Should -Match "PSTypeName = 'PSWinUtil.KeyboardRemapping'"
    }
}

Describe 'Public command help' {
    BeforeAll {
        Import-Module -Name $script:ManifestPath -Force -ErrorAction Stop
        $script:PublicFunctionNames = @(
            (Get-Module -Name 'PSWinUtil' -ErrorAction Stop).ExportedFunctions.Keys
        )
    }

    It 'is complete for every exported function' {
        $commonParameterNames = @(
            'Verbose'
            'Debug'
            'ErrorAction'
            'WarningAction'
            'InformationAction'
            'ErrorVariable'
            'WarningVariable'
            'InformationVariable'
            'OutVariable'
            'OutBuffer'
            'PipelineVariable'
            'ProgressAction'
            'WhatIf'
            'Confirm'
        )
        foreach ($functionName in $script:PublicFunctionNames) {
            $help = Get-Help -Name $functionName -Full

            $help.Synopsis | Should -Not -BeNullOrEmpty
            @($help.Description).Count | Should -BeGreaterThan 0
            @($help.Examples.Example).Count | Should -BeGreaterThan 0

            $command = Get-Command -Name $functionName -Module 'PSWinUtil'
            foreach ($parameterName in $command.Parameters.Keys) {
                if ($parameterName -in $commonParameterNames) {
                    continue
                }

                $parameterHelp = @(
                    $help.Parameters.Parameter |
                        Where-Object { $_.Name -eq $parameterName }
                )
                $parameterHelp.Count | Should -Be 1
                $parameterHelp[0].Description | Should -Not -BeNullOrEmpty
            }
        }
    }
}

Describe 'Private command help' {
    BeforeAll {
        Import-Module -Name $script:ManifestPath -Force -ErrorAction Stop
        $script:Module = Get-Module -Name 'PSWinUtil' -ErrorAction Stop
        $script:ExportedFunctionNames = @($script:Module.ExportedFunctions.Keys)
        $script:PrivateFunctionNames = @(
            & $script:Module {
                Get-Command -CommandType Function |
                    Where-Object { $_.ModuleName -eq 'PSWinUtil' } |
                    Select-Object -ExpandProperty Name
                } |
                    Where-Object { $_ -notin $script:ExportedFunctionNames }
        )
    }

    It 'is complete for every internal function' {
        foreach ($functionName in $script:PrivateFunctionNames) {
            $help = & $script:Module {
                param($Name)

                Get-Help -Name $Name -Full
            } $functionName

            $help.Synopsis | Should -Not -BeNullOrEmpty
            @($help.Description).Count | Should -BeGreaterThan 0
            @($help.Examples.Example).Count | Should -BeGreaterThan 0

            $command = & $script:Module {
                param($Name)

                Get-Command -Name $Name -CommandType Function
            } $functionName
            foreach ($parameterName in $command.Parameters.Keys) {
                if ($parameterName -in @(
                        'Verbose'
                        'Debug'
                        'ErrorAction'
                        'WarningAction'
                        'InformationAction'
                        'ErrorVariable'
                        'WarningVariable'
                        'InformationVariable'
                        'OutVariable'
                        'OutBuffer'
                        'PipelineVariable'
                        'ProgressAction'
                        'WhatIf'
                        'Confirm'
                    )) {
                    continue
                }

                $parameterHelp = @(
                    $help.Parameters.Parameter |
                        Where-Object { $_.Name -eq $parameterName }
                )
                $parameterHelp.Count | Should -Be 1
                $parameterHelp[0].Description | Should -Not -BeNullOrEmpty
            }
        }
    }
}
