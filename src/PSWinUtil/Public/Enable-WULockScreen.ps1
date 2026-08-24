function Enable-WULockScreen {
    <#
    .SYNOPSIS
    Enables the lock screen.

    .DESCRIPTION
    Applies the Enable option for the lock screen. Registry changes are delegated to the registry property commands.

    .EXAMPLE
    Enable-WULockScreen

    Enables the lock screen.

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
        -Name 'LockScreen' `
        -Option 'Enable' `
        @shouldProcessParameters
}
