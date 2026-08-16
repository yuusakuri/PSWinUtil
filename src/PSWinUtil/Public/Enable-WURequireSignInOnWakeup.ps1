function Enable-WURequireSignInOnWakeup {
    <#
    .SYNOPSIS
    Enables sign-in after wakeup.

    .DESCRIPTION
    Applies the Enable option for sign-in after wakeup. Registry changes are delegated to the registry property commands.

    .EXAMPLE
    Enable-WURequireSignInOnWakeup

    Enables sign-in after wakeup.

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
        -Name 'RequireSignInOnWakeup' `
        -Option 'Enable' `
        @shouldProcessParameters
}
