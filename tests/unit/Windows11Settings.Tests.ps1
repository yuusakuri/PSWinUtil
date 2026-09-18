BeforeAll {
    . (Join-Path -Path $PSScriptRoot -ChildPath '../UnitTestBootstrap.ps1')

    InModuleScope -ModuleName PSWinUtil {
        function script:New-WinUserLanguageList {
            param($Language)

            @($Language)
        }

        function script:Set-WinUserLanguageList {
            param($LanguageList, [switch]$Force)

            $LanguageList | Out-Null
            $Force | Out-Null
            throw 'Language changes must be replaced by the test backend.'
        }
    }
}

Describe 'Set-WUJapaneseKeyboardLayout' {
    BeforeEach {
        $script:SubstitutePath = 'Registry::HKEY_CURRENT_USER\Keyboard Layout\Substitutes'
        $script:PreloadPath = 'Registry::HKEY_CURRENT_USER\Keyboard Layout\Preload'
        $script:LayoutPath = 'Registry::HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\Keyboard Layouts\00000411'
        $script:DriverPath = 'Registry::HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Services\i8042prt\Parameters'
        $script:Registry = @{
            "$($script:SubstitutePath)|00000411" = [pscustomobject]@{ Value = 'old substitute'; Type = 'String' }
            "$($script:DriverPath)|Unrelated" = [pscustomobject]@{ Value = 'keep'; Type = 'String' }
        }
        $script:Languages = @('en-US')
        Mock -CommandName Set-WinUserLanguageList -ModuleName PSWinUtil -MockWith {
            $script:Languages = @($LanguageList)
        }
        Mock -CommandName Get-WURegistryProperty -ModuleName PSWinUtil -MockWith {
            $script:Registry["$Path|$Name"]
        }
        Mock -CommandName Test-Path -ModuleName PSWinUtil -ParameterFilter { $LiteralPath -like 'Registry::*' } -MockWith { $true }
        Mock -CommandName New-ItemProperty -ModuleName PSWinUtil -ParameterFilter { $LiteralPath -like 'Registry::*' } -MockWith {
            $script:Registry["$LiteralPath|$Name"] = [pscustomobject]@{ Value = $Value; Type = $PropertyType }
        }
        Mock -CommandName Remove-ItemProperty -ModuleName PSWinUtil -ParameterFilter { $LiteralPath -like 'Registry::*' } -MockWith {
            $script:Registry.Remove("$LiteralPath|$Name")
        }
    }

    It 'configures the Japanese IME for a <Layout> physical keyboard' -ForEach @(
        @{ Layout = 'US'; LayoutFile = 'KBDUS.DLL'; LayerDriver = 'kbd101.dll'; Identifier = 'PCAT_101KEY'; Subtype = 0 }
        @{ Layout = 'Japanese'; LayoutFile = 'KBDJPN.DLL'; LayerDriver = 'kbd106.dll'; Identifier = 'PCAT_106KEY'; Subtype = 2 }
    ) {
        $result = Set-WUJapaneseKeyboardLayout -Layout $Layout

        $result.Layout | Should -Be $Layout
        $result.RestartRequired | Should -BeTrue
        $result.PSObject.TypeNames | Should -Contain 'PSWinUtil.JapaneseKeyboardLayout'
        $script:Languages | Should -Be @('ja-JP')
        $script:Registry.ContainsKey("$($script:SubstitutePath)|00000411") | Should -BeFalse
        $script:Registry["$($script:PreloadPath)|1"].Value | Should -Be '00000411'
        $script:Registry["$($script:LayoutPath)|Layout File"].Value | Should -Be $LayoutFile
        $script:Registry["$($script:DriverPath)|LayerDriver JPN"].Value | Should -Be $LayerDriver
        $script:Registry["$($script:DriverPath)|OverrideKeyboardIdentifier"].Value | Should -Be $Identifier
        $script:Registry["$($script:DriverPath)|OverrideKeyboardSubtype"].Value | Should -Be $Subtype
        $script:Registry["$($script:DriverPath)|OverrideKeyboardSubtype"].Type | Should -Be 'DWord'
        $script:Registry["$($script:DriverPath)|OverrideKeyboardType"].Value | Should -Be 7
        $script:Registry["$($script:DriverPath)|Unrelated"].Value | Should -Be 'keep'
    }

    It 'preserves registry values and languages when previewing a layout change' {
        Set-WUJapaneseKeyboardLayout -Layout US -WhatIf

        $script:Languages | Should -Be @('en-US')
        $script:Registry.Count | Should -Be 2
        $script:Registry["$($script:SubstitutePath)|00000411"].Value | Should -Be 'old substitute'
        $script:Registry["$($script:DriverPath)|Unrelated"].Value | Should -Be 'keep'
    }
}
