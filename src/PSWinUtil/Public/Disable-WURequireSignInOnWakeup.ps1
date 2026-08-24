function Disable-WURequireSignInOnWakeup {
    <#
    .SYNOPSIS
    Disables sign-in after wakeup.

    .DESCRIPTION
    Applies the Disable option for sign-in after wakeup. Registry changes are delegated to the registry property commands.

    .EXAMPLE
    Disable-WURequireSignInOnWakeup

    Disables sign-in after wakeup.

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

    Set-WURegistrySetting `
        -Name 'RequireSignInOnWakeup' `
        -Option 'Disable' `
        @shouldProcessParameters
}
