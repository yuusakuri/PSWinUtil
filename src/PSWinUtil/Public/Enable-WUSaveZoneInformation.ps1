function Enable-WUSaveZoneInformation {
    <#
    .SYNOPSIS
    Enables download zone information.

    .DESCRIPTION
    Applies the Enable option for download zone information. Registry changes are delegated to the registry property commands.

    .EXAMPLE
    Enable-WUSaveZoneInformation

    Enables download zone information.

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

    $shouldProcessParameters = Select-WUBoundParameter `
        -BoundParameters $PSBoundParameters `
        -Name 'WhatIf', 'Confirm'

    Set-WURegistrySetting `
        -Name 'SaveZoneInformation' `
        -Option 'Enable' `
        @shouldProcessParameters
}
