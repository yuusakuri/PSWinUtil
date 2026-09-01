BeforeAll {
    . (Join-Path -Path $PSScriptRoot -ChildPath '../UnitTestBootstrap.ps1')

    $script:KeyboardLayoutPath = 'Registry::HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\Keyboard Layout'
    $script:Mappings = @(
        [pscustomobject]@{ SourceScanCode = [uint16]0x003A; DestinationScanCode = [uint16]0x001D }
        [pscustomobject]@{ SourceScanCode = [uint16]0xE05B; DestinationScanCode = [uint16]0x0000 }
    )
    $script:ValidValue = InModuleScope -ModuleName PSWinUtil -Parameters @{ Mappings = $script:Mappings } {
        ConvertTo-WUScancodeMap -Mapping $Mappings
    }
}

Describe 'Scancode Map conversion' {
    It 'writes the exact little-endian binary format' {
        $expected = [byte[]](
            0, 0, 0, 0, 0, 0, 0, 0,
            3, 0, 0, 0,
            0x1D, 0x00, 0x3A, 0x00,
            0x00, 0x00, 0x5B, 0xE0,
            0, 0, 0, 0
        )

        $script:ValidValue | Should -Be $expected
    }

    It 'writes a valid empty map' {
        $value = InModuleScope -ModuleName PSWinUtil {
            ConvertTo-WUScancodeMap -Mapping @()
        }

        $value | Should -Be ([byte[]](0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0))
    }

    It 'round trips every mapping' {
        $result = InModuleScope -ModuleName PSWinUtil -Parameters @{ Value = $script:ValidValue } {
            @(ConvertFrom-WUScancodeMap -Value $Value)
        }

        $result.Count | Should -Be 2
        $result[0].SourceScanCode | Should -Be 0x003A
        $result[0].DestinationScanCode | Should -Be 0x001D
        $result[1].SourceScanCode | Should -Be 0xE05B
        $result[1].DestinationScanCode | Should -Be 0
    }

    It 'rejects an invalid length' {
        InModuleScope -ModuleName PSWinUtil {
            { ConvertFrom-WUScancodeMap -Value ([byte[]]::new(15)) } | Should -Throw '*length*'
        }
    }

    It 'rejects an invalid header' {
        $value = [byte[]]$script:ValidValue.Clone()
        $value[0] = 1

        InModuleScope -ModuleName PSWinUtil -Parameters @{ Value = $value } {
            { ConvertFrom-WUScancodeMap -Value $Value } | Should -Throw '*header*'
        }
    }

    It 'rejects an invalid entry count' {
        $value = [byte[]]$script:ValidValue.Clone()
        $value[8] = 2

        InModuleScope -ModuleName PSWinUtil -Parameters @{ Value = $value } {
            { ConvertFrom-WUScancodeMap -Value $Value } | Should -Throw '*entry count*'
        }
    }

    It 'rejects an invalid terminator' {
        $value = [byte[]]$script:ValidValue.Clone()
        $value[$value.Length - 1] = 1

        InModuleScope -ModuleName PSWinUtil -Parameters @{ Value = $value } {
            { ConvertFrom-WUScancodeMap -Value $Value } | Should -Throw '*terminator*'
        }
    }

    It 'rejects duplicate source scan codes when parsing' {
        $value = [byte[]]$script:ValidValue.Clone()
        $value[18] = $value[14]
        $value[19] = $value[15]

        InModuleScope -ModuleName PSWinUtil -Parameters @{ Value = $value } {
            { ConvertFrom-WUScancodeMap -Value $Value } | Should -Throw '*duplicate*'
        }
    }

    It 'rejects zero and duplicate source scan codes when writing' {
        InModuleScope -ModuleName PSWinUtil {
            $zeroSource = [pscustomobject]@{ SourceScanCode = 0; DestinationScanCode = 1 }
            { ConvertTo-WUScancodeMap -Mapping $zeroSource } | Should -Throw '*cannot be zero*'

            $duplicates = @(
                [pscustomobject]@{ SourceScanCode = 58; DestinationScanCode = 29 }
                [pscustomobject]@{ SourceScanCode = 58; DestinationScanCode = 30 }
            )
            { ConvertTo-WUScancodeMap -Mapping $duplicates } | Should -Throw '*duplicate*'
        }
    }

    It 'rejects values outside unsigned 16-bit integer limits' {
        InModuleScope -ModuleName PSWinUtil {
            $negativeDestination = [pscustomobject]@{ SourceScanCode = 58; DestinationScanCode = -1 }
            { ConvertTo-WUScancodeMap -Mapping $negativeDestination } | Should -Throw '*unsigned 16-bit*'

            $largeSource = [pscustomobject]@{ SourceScanCode = 65536; DestinationScanCode = 29 }
            { ConvertTo-WUScancodeMap -Mapping $largeSource } | Should -Throw '*unsigned 16-bit*'

            $fractionalSource = [pscustomobject]@{ SourceScanCode = 58.5; DestinationScanCode = 29 }
            { ConvertTo-WUScancodeMap -Mapping $fractionalSource } | Should -Throw '*unsigned 16-bit*'
        }
    }
}

Describe 'Get-WUKeyboardRemapping' {
    It 'returns every mapping with a restart flag' {
        Mock -CommandName Get-WURegistryProperty -ModuleName PSWinUtil -MockWith {
            [pscustomobject]@{ Type = 'Binary'; Value = $script:ValidValue }
        }

        $results = @(Get-WUKeyboardRemapping)

        $results.Count | Should -Be 2
        $results[0].PSObject.TypeNames | Should -Contain 'PSWinUtil.KeyboardRemapping'
        $results[0].RestartRequired | Should -BeTrue
        $results[1].DestinationScanCode | Should -Be 0
    }

    It 'returns no output for a missing registry value' {
        Mock -CommandName Get-WURegistryProperty -ModuleName PSWinUtil

        Get-WUKeyboardRemapping | Should -BeNullOrEmpty
    }

    It 'rejects a registry value with the wrong type' {
        Mock -CommandName Get-WURegistryProperty -ModuleName PSWinUtil -MockWith {
            [pscustomobject]@{ Type = 'String'; Value = 'invalid' }
        }

        { Get-WUKeyboardRemapping } | Should -Throw '*Binary*'
    }
}

Describe 'Set-WUKeyboardRemapping' {
    BeforeEach {
        Mock -CommandName Get-WURegistryProperty -ModuleName PSWinUtil -MockWith {
            [pscustomobject]@{ Type = 'Binary'; Value = $script:ValidValue }
        }
        Mock -CommandName Set-WURegistryProperty -ModuleName PSWinUtil -MockWith {
            $script:StoredValue = [byte[]]$Value
        }
        Mock -CommandName Get-WUKeyboardRemapping -ModuleName PSWinUtil -MockWith {
            [pscustomobject]@{
                PSTypeName = 'PSWinUtil.KeyboardRemapping'
                SourceScanCode = [uint16]0x0046
                DestinationScanCode = [uint16]0x0020
                RestartRequired = $true
            }
        }
        $script:StoredValue = $null
    }

    It 'adds a mapping and preserves existing mappings' {
        Set-WUKeyboardRemapping -SourceScanCode 0x0046 -DestinationScanCode 0x0020

        $results = InModuleScope -ModuleName PSWinUtil -Parameters @{ Value = $script:StoredValue } {
            @(ConvertFrom-WUScancodeMap -Value $Value)
        }
        $results.Count | Should -Be 3
        @($results.SourceScanCode) | Should -Contain 0x003A
        @($results.SourceScanCode) | Should -Contain 0xE05B
        @($results.SourceScanCode) | Should -Contain 0x0046
    }

    It 'updates an existing source without adding a duplicate' {
        Set-WUKeyboardRemapping -SourceScanCode 0x003A -DestinationScanCode 0x002A

        $results = InModuleScope -ModuleName PSWinUtil -Parameters @{ Value = $script:StoredValue } {
            @(ConvertFrom-WUScancodeMap -Value $Value)
        }
        $results.Count | Should -Be 2
        $updated = @($results | Where-Object { $_.SourceScanCode -eq 0x003A })[0]
        $updated.DestinationScanCode | Should -Be 0x002A
    }

    It 'allows a zero destination to disable a key' {
        Set-WUKeyboardRemapping -SourceScanCode 0x003A -DestinationScanCode 0

        $results = InModuleScope -ModuleName PSWinUtil -Parameters @{ Value = $script:StoredValue } {
            @(ConvertFrom-WUScancodeMap -Value $Value)
        }
        @($results | Where-Object { $_.SourceScanCode -eq 0x003A })[0].DestinationScanCode |
            Should -Be 0
    }

    It 'forwards WhatIf to the registry command' {
        Set-WUKeyboardRemapping -SourceScanCode 0x0046 -DestinationScanCode 0x0020 -WhatIf

        Should -Invoke -CommandName Set-WURegistryProperty -ModuleName PSWinUtil -Times 1 -Exactly -ParameterFilter {
            $WhatIf
        }
    }

    It 'returns the stored mapping with PassThru' {
        $result = Set-WUKeyboardRemapping -SourceScanCode 0x0046 -DestinationScanCode 0x0020 -PassThru

        $result.SourceScanCode | Should -Be 0x0046
        $result.RestartRequired | Should -BeTrue
    }
}

Describe 'Remove-WUKeyboardRemapping' {
    BeforeEach {
        Mock -CommandName Get-WURegistryProperty -ModuleName PSWinUtil -MockWith {
            [pscustomobject]@{ Type = 'Binary'; Value = $script:ValidValue }
        }
        Mock -CommandName Set-WURegistryProperty -ModuleName PSWinUtil -MockWith {
            $script:StoredValue = [byte[]]$Value
        }
        Mock -CommandName Remove-WURegistryProperty -ModuleName PSWinUtil
        $script:StoredValue = $null
    }

    It 'removes one mapping and preserves the other mapping' {
        Remove-WUKeyboardRemapping -SourceScanCode 0x003A

        $results = InModuleScope -ModuleName PSWinUtil -Parameters @{ Value = $script:StoredValue } {
            @(ConvertFrom-WUScancodeMap -Value $Value)
        }
        @($results).Count | Should -Be 1
        $results[0].SourceScanCode | Should -Be 0xE05B
        Should -Invoke -CommandName Remove-WURegistryProperty -ModuleName PSWinUtil -Times 0 -Exactly
    }

    It 'removes the registry property when the last mapping is removed' {
        $oneMappingValue = InModuleScope -ModuleName PSWinUtil {
            ConvertTo-WUScancodeMap -Mapping ([pscustomobject]@{
                    SourceScanCode = 58
                    DestinationScanCode = 29
                })
        }
        Mock -CommandName Get-WURegistryProperty -ModuleName PSWinUtil -MockWith {
            [pscustomobject]@{ Type = 'Binary'; Value = $oneMappingValue }
        }

        Remove-WUKeyboardRemapping -SourceScanCode 58

        Should -Invoke -CommandName Remove-WURegistryProperty -ModuleName PSWinUtil -Times 1 -Exactly
        Should -Invoke -CommandName Set-WURegistryProperty -ModuleName PSWinUtil -Times 0 -Exactly
    }

    It 'removes the complete registry property with All' {
        Remove-WUKeyboardRemapping -All

        Should -Invoke -CommandName Remove-WURegistryProperty -ModuleName PSWinUtil -Times 1 -Exactly -ParameterFilter {
            $Path -eq $script:KeyboardLayoutPath -and $Name -eq 'Scancode Map'
        }
    }

    It 'removes an invalid registry value with All without parsing it' {
        Mock -CommandName Get-WURegistryProperty -ModuleName PSWinUtil -MockWith {
            [pscustomobject]@{ Type = 'String'; Value = 'invalid' }
        }

        { Remove-WUKeyboardRemapping -All } | Should -Not -Throw
        Should -Invoke -CommandName Remove-WURegistryProperty -ModuleName PSWinUtil -Times 1 -Exactly
    }

    It 'does nothing when the source mapping is missing' {
        Remove-WUKeyboardRemapping -SourceScanCode 0x0046

        Should -Invoke -CommandName Remove-WURegistryProperty -ModuleName PSWinUtil -Times 0 -Exactly
        Should -Invoke -CommandName Set-WURegistryProperty -ModuleName PSWinUtil -Times 0 -Exactly
    }

    It 'forwards WhatIf to the registry command' {
        Remove-WUKeyboardRemapping -All -WhatIf

        Should -Invoke -CommandName Remove-WURegistryProperty -ModuleName PSWinUtil -Times 1 -Exactly -ParameterFilter {
            $WhatIf
        }
    }
}
