function Disable-WUEdgeFirstRunExperience {
    <#
    .SYNOPSIS
    Disables the Microsoft Edge first-run experience.

    .DESCRIPTION
    Applies the Disable option for the Microsoft Edge first-run experience. Registry changes are delegated to the registry property commands.

    .EXAMPLE
    Disable-WUEdgeFirstRunExperience

    Disables the Microsoft Edge first-run experience.

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
    Set-WURegistrySetting -Name 'EdgeFirstRunExperience' -Option 'Disable' @shouldProcessParameters
}
