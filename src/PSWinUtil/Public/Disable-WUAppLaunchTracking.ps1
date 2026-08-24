function Disable-WUAppLaunchTracking {
    <#
    .SYNOPSIS
    Disables application launch tracking.

    .DESCRIPTION
    Applies the Disable option for application launch tracking. Registry changes are delegated to the registry property commands.

    .EXAMPLE
    Disable-WUAppLaunchTracking

    Disables application launch tracking.

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
        -Name 'AppLaunchTracking' `
        -Option 'Disable' `
        @shouldProcessParameters
}
