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

    $shouldProcessParameters = @{}
    foreach ($parameterName in @('WhatIf', 'Confirm')) {
        if ($PSBoundParameters.ContainsKey($parameterName)) {
            $shouldProcessParameters[$parameterName] = $PSBoundParameters[$parameterName]
        }
    }

    Set-WURegistrySettingOption `
        -Name 'AppLaunchTracking' `
        -Option 'Disable' `
        @shouldProcessParameters
}
