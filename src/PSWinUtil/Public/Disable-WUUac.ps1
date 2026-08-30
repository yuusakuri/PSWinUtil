function Disable-WUUac {
    <#
    .SYNOPSIS
    Disables User Account Control.

    .DESCRIPTION
    Applies the Disable option for User Account Control. Registry changes are delegated to the registry property commands.

    .EXAMPLE
    Disable-WUUac

    Disables User Account Control.

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
    Set-WURegistrySetting -Name 'Uac' -Option 'Disable' @shouldProcessParameters
}
