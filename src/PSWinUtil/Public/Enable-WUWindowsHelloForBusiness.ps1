function Enable-WUWindowsHelloForBusiness {
    <#
    .SYNOPSIS
    Enables Windows Hello for Business.

    .DESCRIPTION
    Applies the Enable option for Windows Hello for Business. Registry changes are delegated to the registry property commands.

    .EXAMPLE
    Enable-WUWindowsHelloForBusiness

    Enables Windows Hello for Business.

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
        -Name 'WindowsHelloForBusiness' `
        -Option 'Enable' `
        @shouldProcessParameters
}
