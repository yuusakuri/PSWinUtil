function Disable-WUAppSuggestions {
    <#
    .SYNOPSIS
    Disables application suggestions.

    .DESCRIPTION
    Applies the Disable option for application suggestions. Registry changes are delegated to the registry property commands.

    .EXAMPLE
    Disable-WUAppSuggestions

    Disables application suggestions.

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
        -Name 'AppSuggestions' `
        -Option 'Disable' `
        @shouldProcessParameters
}
