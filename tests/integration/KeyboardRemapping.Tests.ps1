BeforeAll {
    $repositoryRoot = Split-Path -Path (Split-Path -Path $PSScriptRoot -Parent) -Parent
    $manifestPath = Join-Path -Path $repositoryRoot -ChildPath 'output/PSWinUtil/PSWinUtil.psd1'
    Import-Module -Name $manifestPath -Force -ErrorAction Stop

    $script:KeyboardLayoutPath = 'Registry::HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\Keyboard Layout'
    $script:IsAdministrator = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole(
        [Security.Principal.WindowsBuiltInRole]::Administrator
    )
}

Describe 'Keyboard remapping commands' {
    BeforeEach {
        $script:SavedProperty = Get-WURegistryProperty -Path $script:KeyboardLayoutPath -Name 'Scancode Map'
        $usedSourceScanCodes = @(Get-WUKeyboardRemapping | Select-Object -ExpandProperty SourceScanCode)
        $script:TestSourceScanCode = @(
            0x7E00..0x7E0F | Where-Object { $_ -notin $usedSourceScanCodes }
        )[0]
    }

    AfterEach {
        if (-not $script:IsAdministrator) {
            return
        }
        if ($null -eq $script:SavedProperty) {
            Remove-WURegistryProperty -Path $script:KeyboardLayoutPath -Name 'Scancode Map' -Confirm:$false
            return
        }
        $restoreParameters = @{
            Path = $script:KeyboardLayoutPath
            Name = 'Scancode Map'
            Value = $script:SavedProperty.Value
            Type = $script:SavedProperty.Type
            Confirm = $false
        }
        Set-WURegistryProperty @restoreParameters
    }

    It 'adds, gets, and removes one mapping' -Skip:(-not $script:IsAdministrator) {
        $existingCount = @(Get-WUKeyboardRemapping).Count

        $mapping = Set-WUKeyboardRemapping -SourceScanCode $script:TestSourceScanCode -DestinationScanCode 0x7E01 -PassThru
        $mapping.SourceScanCode | Should -Be $script:TestSourceScanCode
        $mapping.DestinationScanCode | Should -Be 0x7E01
        $mapping.RestartRequired | Should -BeTrue
        @(Get-WUKeyboardRemapping).Count | Should -Be ($existingCount + 1)

        Remove-WUKeyboardRemapping -SourceScanCode $script:TestSourceScanCode
        @(Get-WUKeyboardRemapping | Where-Object { $_.SourceScanCode -eq $script:TestSourceScanCode }).Count |
            Should -Be 0
    }

    It 'does not add a mapping with WhatIf' -Skip:(-not $script:IsAdministrator) {
        Set-WUKeyboardRemapping -SourceScanCode $script:TestSourceScanCode -DestinationScanCode 0x7E01 -WhatIf

        @(Get-WUKeyboardRemapping | Where-Object { $_.SourceScanCode -eq $script:TestSourceScanCode }).Count |
            Should -Be 0
    }
}
