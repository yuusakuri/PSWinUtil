function Set-WUJapaneseKeyboardLayout {
    <#
    .SYNOPSIS
    Sets the physical layout used with the Japanese Microsoft IME.

    .DESCRIPTION
    Replaces the current user language list with Japanese, configures the Japanese preload entry, and sets the Japanese keyboard layout and keyboard driver registry values for a US or Japanese physical keyboard. The command does not restart Windows. A restart is required. Physical key behavior, Microsoft IME input, and restoration still require verification on supported Windows 11 Home and Pro devices.

    .PARAMETER Layout
    Specifies US or Japanese.

    .EXAMPLE
    Set-WUJapaneseKeyboardLayout -Layout US

    Configures the Japanese Microsoft IME for a US physical keyboard.

    .EXAMPLE
    Set-WUJapaneseKeyboardLayout -Layout Japanese

    Configures the Japanese Microsoft IME for a Japanese physical keyboard.

    .INPUTS
    None

    .OUTPUTS
    PSWinUtil.JapaneseKeyboardLayout
    #>
    [CmdletBinding(SupportsShouldProcess = $true)]
    [OutputType('PSWinUtil.JapaneseKeyboardLayout')]
    param(
        [Parameter(Mandatory = $true, Position = 0)]
        [ValidateSet('US', 'Japanese')]
        [string]$Layout
    )

    foreach ($commandName in @('New-WinUserLanguageList', 'Set-WinUserLanguageList')) {
        if ($null -eq (Get-Command -Name $commandName -CommandType Cmdlet -ErrorAction Ignore)) {
            throw "The required Windows command was not found: $commandName"
        }
    }

    $languageList = New-WinUserLanguageList -Language 'ja-JP'
    if ($PSCmdlet.ShouldProcess('Current user language list', 'Set the language list to Japanese')) {
        Set-WinUserLanguageList -LanguageList $languageList -Force
    }

    $shouldProcessParameters = @{}
    foreach ($parameterName in @('WhatIf', 'Confirm')) {
        if ($PSBoundParameters.ContainsKey($parameterName)) {
            $shouldProcessParameters[$parameterName] = $PSBoundParameters[$parameterName]
        }
    }

    $substituteParameters = @{
        Path = 'Registry::HKEY_CURRENT_USER\Keyboard Layout\Substitutes'
        Name = '00000411'
    }
    Remove-WURegistryProperty @substituteParameters @shouldProcessParameters

    $preloadParameters = @{
        Path = 'Registry::HKEY_CURRENT_USER\Keyboard Layout\Preload'
        Name = '1'
        Value = '00000411'
        Type = 'String'
    }
    Set-WURegistryProperty @preloadParameters @shouldProcessParameters

    $layoutFile = 'KBDUS.DLL'
    $layerDriver = 'kbd101.dll'
    $keyboardIdentifier = 'PCAT_101KEY'
    $keyboardSubtype = 0
    if ($Layout -eq 'Japanese') {
        $layoutFile = 'KBDJPN.DLL'
        $layerDriver = 'kbd106.dll'
        $keyboardIdentifier = 'PCAT_106KEY'
        $keyboardSubtype = 2
    }

    $layoutPath = 'Registry::HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\Keyboard Layouts\00000411'
    $layoutParameters = @{
        Path = $layoutPath
        Name = 'Layout File'
        Value = $layoutFile
        Type = 'String'
    }
    Set-WURegistryProperty @layoutParameters @shouldProcessParameters

    $driverPath = 'Registry::HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Services\i8042prt\Parameters'
    $driverValues = @(
        @{ Name = 'LayerDriver JPN'; Value = $layerDriver; Type = 'String' }
        @{ Name = 'OverrideKeyboardIdentifier'; Value = $keyboardIdentifier; Type = 'String' }
        @{ Name = 'OverrideKeyboardSubtype'; Value = $keyboardSubtype; Type = 'DWord' }
        @{ Name = 'OverrideKeyboardType'; Value = 7; Type = 'DWord' }
    )
    foreach ($driverValue in $driverValues) {
        $driverParameters = @{
            Path = $driverPath
            Name = $driverValue.Name
            Value = $driverValue.Value
            Type = $driverValue.Type
        }
        Set-WURegistryProperty @driverParameters @shouldProcessParameters
    }

    [pscustomobject]@{
        PSTypeName = 'PSWinUtil.JapaneseKeyboardLayout'
        Layout = $Layout
        RestartRequired = $true
    }
}
