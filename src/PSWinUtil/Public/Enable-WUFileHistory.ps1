function Enable-WUFileHistory {
    <#
    .SYNOPSIS
    Enables File History.

    .DESCRIPTION
    Applies the Enable option for File History. Registry changes are delegated to the registry property commands.

    .EXAMPLE
    Enable-WUFileHistory

    Enables File History.

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
    Set-WURegistrySetting -Name 'FileHistory' -Option 'Enable' @shouldProcessParameters
}
