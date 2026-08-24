function Enable-WULongPaths {
    <#
    .SYNOPSIS
    Enables long Windows paths.

    .DESCRIPTION
    Applies the Enable option for long Windows paths. Registry changes are delegated to the registry property commands.

    .EXAMPLE
    Enable-WULongPaths

    Enables long Windows paths.

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
        -Name 'LongPaths' `
        -Option 'Enable' `
        @shouldProcessParameters
}
