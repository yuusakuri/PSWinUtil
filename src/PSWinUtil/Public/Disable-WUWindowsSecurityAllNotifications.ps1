function Disable-WUWindowsSecurityAllNotifications {
    <#
    .SYNOPSIS
    Disables all Windows Security notifications.

    .DESCRIPTION
    Applies the Disable option for all Windows Security notifications. Registry changes are delegated to the registry property commands.

    .EXAMPLE
    Disable-WUWindowsSecurityAllNotifications

    Disables all Windows Security notifications.

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

    $shouldProcessParameters = @{}
    foreach ($parameterName in @('WhatIf', 'Confirm')) {
        if ($PSBoundParameters.ContainsKey($parameterName)) {
            $shouldProcessParameters[$parameterName] = $PSBoundParameters[$parameterName]
        }
    }

    Set-WURegistrySetting `
        -Name 'WindowsSecurityAllNotifications' `
        -Option 'Disable' `
        @shouldProcessParameters
}
