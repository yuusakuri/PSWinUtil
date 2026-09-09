BeforeAll {
    . (Join-Path -Path $PSScriptRoot -ChildPath '../UnitTestBootstrap.ps1')
}

Describe 'Keyboard mapping public behavior with a registry fake' {
    BeforeEach {
        $script:StoredMapping = $null
        Mock Get-WURegistryProperty -ModuleName PSWinUtil { $script:StoredMapping }
        Mock Set-WURegistryProperty -ModuleName PSWinUtil {
            $script:StoredMapping = [pscustomobject]@{ Type = $Type; Value = [byte[]]$Value }
        }
        Mock Set-WURegistryProperty -ModuleName PSWinUtil {} -ParameterFilter { $WhatIf }
        Mock Remove-WURegistryProperty -ModuleName PSWinUtil {
            $script:StoredMapping = $null
        }
        Mock Remove-WURegistryProperty -ModuleName PSWinUtil {} -ParameterFilter { $WhatIf }
    }

    It 'encodes mappings in the Windows Scancode Map format and returns their state' {
        Set-WUKeyboardRemapping -SourceScanCode 58 -DestinationScanCode 29
        Set-WUKeyboardRemapping -SourceScanCode 57435 -DestinationScanCode 0
        $script:StoredMapping.Value | Should -Be ([byte[]]@(0, 0, 0, 0, 0, 0, 0, 0, 3, 0, 0, 0, 29, 0, 58, 0, 0, 0, 91, 224, 0, 0, 0, 0))
        $result = @(Get-WUKeyboardRemapping)
        $result | Should -HaveCount 2
        $result[0].SourceScanCode | Should -Be 58
        $result[0].DestinationScanCode | Should -Be 29
        $result[1].DestinationScanCode | Should -Be 0
        $result.RestartRequired | Should -Not -Contain $false
    }

    It 'updates a source without duplicates and removes only the selected mapping' {
        Set-WUKeyboardRemapping -SourceScanCode 1 -DestinationScanCode 65535
        Set-WUKeyboardRemapping -SourceScanCode 65535 -DestinationScanCode 0
        $updated = Set-WUKeyboardRemapping -SourceScanCode 1 -DestinationScanCode 30 -PassThru
        $updated.DestinationScanCode | Should -Be 30
        @(Get-WUKeyboardRemapping) | Should -HaveCount 2
        Remove-WUKeyboardRemapping -SourceScanCode 1
        (Get-WUKeyboardRemapping).SourceScanCode | Should -Be 65535
        Remove-WUKeyboardRemapping -SourceScanCode 100
        (Get-WUKeyboardRemapping).SourceScanCode | Should -Be 65535
        Remove-WUKeyboardRemapping -SourceScanCode 65535
        $script:StoredMapping | Should -BeNullOrEmpty
        @(Get-WUKeyboardRemapping) | Should -HaveCount 0
    }

    It 'preserves stored mappings during previews' {
        Set-WUKeyboardRemapping -SourceScanCode 58 -DestinationScanCode 29
        Set-WUKeyboardRemapping -SourceScanCode 58 -DestinationScanCode 0 -WhatIf
        Remove-WUKeyboardRemapping -All -WhatIf
        Remove-WUKeyboardRemapping -SourceScanCode 58 -WhatIf
        (Get-WUKeyboardRemapping).DestinationScanCode | Should -Be 29
    }

    It 'rejects malformed stored data and can remove it without parsing' -TestCases @(
        @{ Bytes = [byte[]]::new(15); ExpectedError = '*length*' }
        @{ Bytes = [byte[]]@(1, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0); ExpectedError = '*header*' }
        @{ Bytes = [byte[]]@(0, 0, 0, 0, 0, 0, 0, 0, 2, 0, 0, 0, 0, 0, 0, 0); ExpectedError = '*entry count*' }
        @{ Bytes = [byte[]]@(0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 1); ExpectedError = '*terminator*' }
        @{ Bytes = [byte[]]@(0, 0, 0, 0, 0, 0, 0, 0, 3, 0, 0, 0, 29, 0, 58, 0, 30, 0, 58, 0, 0, 0, 0, 0); ExpectedError = '*duplicate*' }
    ) {
        param($Bytes, $ExpectedError)
        $script:StoredMapping = [pscustomobject]@{ Type = 'Binary'; Value = $Bytes }
        { Get-WUKeyboardRemapping } | Should -Throw $ExpectedError
        { Set-WUKeyboardRemapping -SourceScanCode 58 -DestinationScanCode 29 } | Should -Throw $ExpectedError
        $script:StoredMapping.Value | Should -Be $Bytes
        Remove-WUKeyboardRemapping -All
        $script:StoredMapping | Should -BeNullOrEmpty
    }

    It 'rejects a stored value of the wrong registry type' {
        $script:StoredMapping = [pscustomobject]@{ Type = 'String'; Value = 'invalid' }
        { Get-WUKeyboardRemapping } | Should -Throw '*Binary*'
        { Set-WUKeyboardRemapping -SourceScanCode 58 -DestinationScanCode 29 } | Should -Throw '*Binary*'
        { Remove-WUKeyboardRemapping -SourceScanCode 58 } | Should -Throw '*Binary*'
        $script:StoredMapping.Value | Should -Be 'invalid'
    }
}
