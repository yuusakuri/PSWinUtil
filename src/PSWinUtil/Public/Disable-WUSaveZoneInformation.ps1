function Disable-WUSaveZoneInformation {
    <#
    .SYNOPSIS
    Disables download zone information.

    .DESCRIPTION
    Applies the Disable option for download zone information. Registry changes are delegated to the registry property commands.

    .EXAMPLE
    Disable-WUSaveZoneInformation

    Disables download zone information.

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
    Set-WURegistrySetting -Name 'SaveZoneInformation' -Option 'Disable' @shouldProcessParameters
}
