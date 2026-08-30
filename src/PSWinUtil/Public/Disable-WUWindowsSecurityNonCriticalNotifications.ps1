function Disable-WUWindowsSecurityNonCriticalNotifications {
    <#
    .SYNOPSIS
    Disables non-critical Windows Security notifications.

    .DESCRIPTION
    Applies the Disable option for non-critical Windows Security notifications. Registry changes are delegated to the registry property commands.

    .EXAMPLE
    Disable-WUWindowsSecurityNonCriticalNotifications

    Disables non-critical Windows Security notifications.

    .INPUTS
    None

    .OUTPUTS
    None
    #>
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute(
        'PSUseSingularNouns',
        '',
        Justification = 'The public API uses the Windows setting name.'
    )]
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute(
        'PSShouldProcess',
        '',
        Justification = 'Registry property commands evaluate ShouldProcess for each delegated change.'
    )]
    [CmdletBinding(SupportsShouldProcess = $true)]
    param()

    $shouldProcessParameters = Select-WUBoundParameter -BoundParameters $PSBoundParameters -Name 'WhatIf', 'Confirm'
    Set-WURegistrySetting -Name 'WindowsSecurityNonCriticalNotifications' -Option 'Disable' @shouldProcessParameters
}
