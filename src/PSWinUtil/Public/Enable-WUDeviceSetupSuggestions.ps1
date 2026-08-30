function Enable-WUDeviceSetupSuggestions {
    <#
    .SYNOPSIS
    Enables device setup suggestions.

    .DESCRIPTION
    Enables the current user setting that suggests ways to finish setting up the device. The registry mapping is applied without restarting Windows. The visible Windows 11 setting behavior still requires verification on supported Home and Pro builds.

    .EXAMPLE
    Enable-WUDeviceSetupSuggestions

    Enables device setup suggestions for the current user.

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
        Justification = 'Registry property commands evaluate ShouldProcess for the delegated change.'
    )]
    [CmdletBinding(SupportsShouldProcess = $true)]
    param()

    $shouldProcessParameters = Select-WUBoundParameter -BoundParameters $PSBoundParameters -Name 'WhatIf', 'Confirm'
    Set-WURegistrySetting -Name 'DeviceSetupSuggestions' -Option 'Enable' @shouldProcessParameters
}
