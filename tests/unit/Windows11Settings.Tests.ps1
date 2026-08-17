BeforeAll {
    $repositoryRoot = Split-Path -Path (Split-Path -Path $PSScriptRoot -Parent) -Parent
    $manifestPath = Join-Path -Path $repositoryRoot -ChildPath 'output/PSWinUtil/PSWinUtil.psd1'
    Import-Module -Name $manifestPath -Force -ErrorAction Stop
}

Describe 'Windows 11 registry setting commands' {
    BeforeEach {
        Mock -CommandName Set-WURegistrySettingOption -ModuleName PSWinUtil
    }

    It 'enables and disables device setup suggestions' {
        Enable-WUDeviceSetupSuggestions
        Disable-WUDeviceSetupSuggestions

        Should -Invoke -CommandName Set-WURegistrySettingOption -ModuleName PSWinUtil -Times 1 -Exactly -ParameterFilter {
            $Name -eq 'DeviceSetupSuggestions' -and $Option -eq 'Enable'
        }
        Should -Invoke -CommandName Set-WURegistrySettingOption -ModuleName PSWinUtil -Times 1 -Exactly -ParameterFilter {
            $Name -eq 'DeviceSetupSuggestions' -and $Option -eq 'Disable'
        }
    }

    It 'sets both taskbar alignments' {
        Set-WUTaskbarAlignment -Alignment Left
        Set-WUTaskbarAlignment -Alignment Center

        Should -Invoke -CommandName Set-WURegistrySettingOption -ModuleName PSWinUtil -Times 1 -Exactly -ParameterFilter {
            $Name -eq 'TaskbarAlignment' -and $Option -eq 'Left'
        }
        Should -Invoke -CommandName Set-WURegistrySettingOption -ModuleName PSWinUtil -Times 1 -Exactly -ParameterFilter {
            $Name -eq 'TaskbarAlignment' -and $Option -eq 'Center'
        }
    }

    It 'sets every taskbar search mode' {
        foreach ($mode in @('Hidden', 'Icon', 'SearchBox')) {
            Set-WUTaskbarSearchMode -Mode $mode
        }

        foreach ($mode in @('Hidden', 'Icon', 'SearchBox')) {
            Should -Invoke -CommandName Set-WURegistrySettingOption -ModuleName PSWinUtil -Times 1 -Exactly -ParameterFilter {
                $Name -eq 'TaskbarSearchMode' -and $Option -eq $mode
            }
        }
    }

    It 'sets all Japanese IME input widths through one setting' {
        Set-WUJapaneseImeHalfWidthInput

        Should -Invoke -CommandName Set-WURegistrySettingOption -ModuleName PSWinUtil -Times 1 -Exactly -ParameterFilter {
            $Name -eq 'JapaneseImeHalfWidthInput' -and $Option -eq 'Set'
        }
    }

    It 'forwards WhatIf to registry settings' {
        Set-WUTaskbarAlignment -Alignment Left -WhatIf

        Should -Invoke -CommandName Set-WURegistrySettingOption -ModuleName PSWinUtil -Times 1 -Exactly -ParameterFilter {
            $WhatIf -eq $true
        }
    }
}

Describe 'Classic context menu commands' {
    BeforeEach {
        Mock -CommandName Set-WURegistryProperty -ModuleName PSWinUtil
        Mock -CommandName Remove-WURegistryProperty -ModuleName PSWinUtil
    }

    It 'sets the empty default registry value when enabled' {
        Enable-WUClassicContextMenu

        Should -Invoke -CommandName Set-WURegistryProperty -ModuleName PSWinUtil -Times 1 -Exactly -ParameterFilter {
            $Path -like '*InprocServer32' -and
            $Name -eq '' -and
            $Value -eq '' -and
            $Type -eq 'String'
        }
    }

    It 'removes only the default registry value when disabled' {
        Disable-WUClassicContextMenu

        Should -Invoke -CommandName Remove-WURegistryProperty -ModuleName PSWinUtil -Times 1 -Exactly -ParameterFilter {
            $Path -like '*InprocServer32' -and $Name -eq ''
        }
    }

    It 'forwards WhatIf to the registry property command' {
        Enable-WUClassicContextMenu -WhatIf

        Should -Invoke -CommandName Set-WURegistryProperty -ModuleName PSWinUtil -Times 1 -Exactly -ParameterFilter {
            $WhatIf -eq $true
        }
    }
}

Describe 'Set-WUJapaneseKeyboardLayout' {
    BeforeAll {
        InModuleScope -ModuleName PSWinUtil {
            function script:New-WinUserLanguageList {
                @('ja-JP')
            }

            function script:Set-WinUserLanguageList {
                param($LanguageList, [switch]$Force)

                $null = $LanguageList
                $null = $Force
            }
        }
    }

    BeforeEach {
        Mock -CommandName Get-Command -ModuleName PSWinUtil -MockWith {
            [pscustomobject]@{ Name = $Name }
        }
        Mock -CommandName New-WinUserLanguageList -ModuleName PSWinUtil -MockWith {
            @('ja-JP')
        }
        Mock -CommandName Set-WinUserLanguageList -ModuleName PSWinUtil
        Mock -CommandName Set-WURegistryProperty -ModuleName PSWinUtil
        Mock -CommandName Remove-WURegistryProperty -ModuleName PSWinUtil
    }

    It 'configures a US physical keyboard' {
        $result = Set-WUJapaneseKeyboardLayout -Layout US

        $result.Layout | Should -Be 'US'
        $result.RestartRequired | Should -BeTrue
        $result.PSObject.TypeNames | Should -Contain 'PSWinUtil.JapaneseKeyboardLayout'
        Should -Invoke -CommandName Set-WinUserLanguageList -ModuleName PSWinUtil -Times 1 -Exactly
        Should -Invoke -CommandName Remove-WURegistryProperty -ModuleName PSWinUtil -Times 1 -Exactly -ParameterFilter {
            $Name -eq '00000411'
        }
        Should -Invoke -CommandName Set-WURegistryProperty -ModuleName PSWinUtil -Times 1 -Exactly -ParameterFilter {
            $Name -eq 'Layout File' -and $Value -eq 'KBDUS.DLL'
        }
        Should -Invoke -CommandName Set-WURegistryProperty -ModuleName PSWinUtil -Times 1 -Exactly -ParameterFilter {
            $Name -eq 'LayerDriver JPN' -and $Value -eq 'kbd101.dll'
        }
        Should -Invoke -CommandName Set-WURegistryProperty -ModuleName PSWinUtil -Times 1 -Exactly -ParameterFilter {
            $Name -eq 'OverrideKeyboardSubtype' -and $Value -eq 0
        }
    }

    It 'configures a Japanese physical keyboard' {
        Set-WUJapaneseKeyboardLayout -Layout Japanese

        Should -Invoke -CommandName Set-WURegistryProperty -ModuleName PSWinUtil -Times 1 -Exactly -ParameterFilter {
            $Name -eq 'Layout File' -and $Value -eq 'KBDJPN.DLL'
        }
        Should -Invoke -CommandName Set-WURegistryProperty -ModuleName PSWinUtil -Times 1 -Exactly -ParameterFilter {
            $Name -eq 'LayerDriver JPN' -and $Value -eq 'kbd106.dll'
        }
        Should -Invoke -CommandName Set-WURegistryProperty -ModuleName PSWinUtil -Times 1 -Exactly -ParameterFilter {
            $Name -eq 'OverrideKeyboardIdentifier' -and $Value -eq 'PCAT_106KEY'
        }
        Should -Invoke -CommandName Set-WURegistryProperty -ModuleName PSWinUtil -Times 1 -Exactly -ParameterFilter {
            $Name -eq 'OverrideKeyboardSubtype' -and $Value -eq 2
        }
    }

    It 'forwards WhatIf and does not set the language list' {
        Set-WUJapaneseKeyboardLayout -Layout US -WhatIf

        Should -Invoke -CommandName Set-WinUserLanguageList -ModuleName PSWinUtil -Times 0 -Exactly
        Should -Invoke -CommandName Set-WURegistryProperty -ModuleName PSWinUtil -Times 6 -Exactly -ParameterFilter {
            $WhatIf -eq $true
        }
        Should -Invoke -CommandName Remove-WURegistryProperty -ModuleName PSWinUtil -Times 1 -Exactly -ParameterFilter {
            $WhatIf -eq $true
        }
    }

    It 'requires the Windows language commands' {
        Mock -CommandName Get-Command -ModuleName PSWinUtil

        { Set-WUJapaneseKeyboardLayout -Layout US } | Should -Throw '*required Windows command*'
        Should -Invoke -CommandName Set-WURegistryProperty -ModuleName PSWinUtil -Times 0 -Exactly
    }
}
