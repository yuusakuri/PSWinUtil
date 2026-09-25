function Import-WURegistryConfig {
    <#
    .SYNOPSIS
    Imports registry configs.

    .DESCRIPTION
    Imports registry config definitions from a PowerShell data file and validates the complete data structure.

    .PARAMETER Path
    Specifies the registry config data file. The built module data file is used by default.

    .EXAMPLE
    Import-WURegistryConfig

    Imports the registry configs distributed with PSWinUtil.

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
        [string]$Path = (Join-Path -Path $PSScriptRoot -ChildPath 'data/RegistryConfig.psd1')
    )

    $fullPath = ConvertTo-WUFullPath -Path $Path
    $registryConfig = Import-PowerShellDataFile -LiteralPath $fullPath -ErrorAction Stop
    if (-not (Test-WURegistryConfig -Config $registryConfig)) {
        throw "The registry config data is invalid: $fullPath"
    }

    $registryConfig
}
