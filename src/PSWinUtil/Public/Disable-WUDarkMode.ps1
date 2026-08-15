function Disable-WUDarkMode {
    <#
    .SYNOPSIS
    Disables dark mode.

    .DESCRIPTION
    Applies the Disable option for dark mode. Registry changes are delegated to the registry property commands.

    .EXAMPLE
    Disable-WUDarkMode

    Disables dark mode.

    .INPUTS
    None

    .OUTPUTS
    None
    #>
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute(
        'PSShouldProcess',
        '',
        Justification = 'Registry property commands evaluate ShouldProcess for each delegated change.'
    )]
    [CmdletBinding(SupportsShouldProcess = $true)]
    param()

    $shouldProcessParameters = @{}
    foreach ($parameterName in @('WhatIf', 'Confirm')) {
        if ($PSBoundParameters.ContainsKey($parameterName)) {
            $shouldProcessParameters[$parameterName] = $PSBoundParameters[$parameterName]
        }
    }

    Set-WURegistrySettingOption `
        -Name 'DarkMode' `
        -Option 'Disable' `
        @shouldProcessParameters
}
