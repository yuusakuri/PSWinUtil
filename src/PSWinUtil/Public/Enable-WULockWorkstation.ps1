function Enable-WULockWorkstation {
    <#
    .SYNOPSIS
    Enables workstation locking.

    .DESCRIPTION
    Applies the Enable option for workstation locking. Registry changes are delegated to the registry property commands.

    .EXAMPLE
    Enable-WULockWorkstation

    Enables workstation locking.

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
        -Name 'LockWorkstation' `
        -Option 'Enable' `
        @shouldProcessParameters
}
