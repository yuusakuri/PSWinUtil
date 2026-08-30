function Enable-WUUac {
    <#
    .SYNOPSIS
    Enables User Account Control.

    .DESCRIPTION
    Applies the Enable option for User Account Control. Registry changes are delegated to the registry property commands.

    .EXAMPLE
    Enable-WUUac

    Enables User Account Control.

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
    Set-WURegistrySetting -Name 'Uac' -Option 'Enable' @shouldProcessParameters
}
