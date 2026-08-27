function Import-WURegistrySetting {
    <#
    .SYNOPSIS
    Imports registry settings.

    .DESCRIPTION
    Imports registry setting definitions from a PowerShell data file and validates the complete data structure.

    .PARAMETER Path
    Specifies the registry setting data file. The built module data file is used by default.

    .EXAMPLE
    Import-WURegistrySetting

    Imports the registry settings distributed with PSWinUtil.

    .INPUTS
    None

    .OUTPUTS
    System.Collections.Hashtable
    #>
    [CmdletBinding()]
    [OutputType([System.Collections.Hashtable])]
    param(
        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [string]$Path = (Join-Path -Path $PSScriptRoot -ChildPath 'data/RegistrySettings.psd1')
    )

    $fullPath = ConvertTo-WUFullPath -Path $Path
    Assert-WUPathProperty -LiteralPath $fullPath -Leaf
    $settingData = Import-PowerShellDataFile -LiteralPath $fullPath -ErrorAction Stop
    if (-not (Test-WURegistrySetting -Setting $settingData)) {
        throw "The registry setting data is invalid: $fullPath"
    }

    $settingData
}
