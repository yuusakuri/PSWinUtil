function Disable-WUFileHistory {
    <#
    .SYNOPSIS
    Disables File History.

    .DESCRIPTION
    Applies the Disable option for File History. Registry changes are delegated to the registry property commands.

    .EXAMPLE
    Disable-WUFileHistory

    Disables File History.

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
        -Name 'FileHistory' `
        -Option 'Disable' `
        @shouldProcessParameters
}
