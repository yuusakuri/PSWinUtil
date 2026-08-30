function Enable-WUDarkMode {
    <#
    .SYNOPSIS
    Enables dark mode.

    .DESCRIPTION
    Applies the Enable option for dark mode. Registry changes are delegated to the registry property commands.

    .EXAMPLE
    Enable-WUDarkMode

    Enables dark mode.

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

    $shouldProcessParameters = Select-WUBoundParameter -BoundParameters $PSBoundParameters -Name 'WhatIf', 'Confirm'
    Set-WURegistrySetting -Name 'DarkMode' -Option 'Enable' @shouldProcessParameters
}
