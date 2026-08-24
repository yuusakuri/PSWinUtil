function Enable-WUEdgeFirstRunExperience {
    <#
    .SYNOPSIS
    Enables the Microsoft Edge first-run experience.

    .DESCRIPTION
    Applies the Enable option for the Microsoft Edge first-run experience. Registry changes are delegated to the registry property commands.

    .EXAMPLE
    Enable-WUEdgeFirstRunExperience

    Enables the Microsoft Edge first-run experience.

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
        -Name 'EdgeFirstRunExperience' `
        -Option 'Enable' `
        @shouldProcessParameters
}
