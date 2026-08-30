function Enable-WUWidgets {
    <#
    .SYNOPSIS
    Enables Windows widgets.

    .DESCRIPTION
    Applies the Enable option for Windows widgets. Registry changes are delegated to the registry property commands.

    .EXAMPLE
    Enable-WUWidgets

    Enables Windows widgets.

    .INPUTS
    None

    .OUTPUTS
    None
    #>
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute(
        'PSUseSingularNouns',
        '',
        Justification = 'The public API uses the Windows setting name.'
    )]
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute(
        'PSShouldProcess',
        '',
        Justification = 'Registry property commands evaluate ShouldProcess for each delegated change.'
    )]
    [CmdletBinding(SupportsShouldProcess = $true)]
    param()

    $shouldProcessParameters = Select-WUBoundParameter -BoundParameters $PSBoundParameters -Name 'WhatIf', 'Confirm'
    Set-WURegistrySetting -Name 'Widgets' -Option 'Enable' @shouldProcessParameters
}
