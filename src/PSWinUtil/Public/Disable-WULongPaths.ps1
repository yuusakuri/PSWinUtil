function Disable-WULongPaths {
    <#
    .SYNOPSIS
    Disables long Windows paths.

    .DESCRIPTION
    Applies the Disable option for long Windows paths. Registry changes are delegated to the registry property commands.

    .EXAMPLE
    Disable-WULongPaths

    Disables long Windows paths.

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

    $shouldProcessParameters = Select-WUBoundParameter `
        -BoundParameters $PSBoundParameters `
        -Name 'WhatIf', 'Confirm'

    Set-WURegistrySetting `
        -Name 'LongPaths' `
        -Option 'Disable' `
        @shouldProcessParameters
}
