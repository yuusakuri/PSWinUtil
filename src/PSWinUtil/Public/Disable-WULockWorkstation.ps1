function Disable-WULockWorkstation {
    <#
    .SYNOPSIS
    Disables workstation locking.

    .DESCRIPTION
    Applies the Disable option for workstation locking. Registry changes are delegated to the registry property commands.

    .EXAMPLE
    Disable-WULockWorkstation

    Disables workstation locking.

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
    Set-WURegistrySetting -Name 'LockWorkstation' -Option 'Disable' @shouldProcessParameters
}
