function Set-WUJapaneseImeHalfWidthInput {
    <#
    .SYNOPSIS
    Sets Microsoft IME space, number, and alphabet input to half width.

    .DESCRIPTION
    Sets the current user Microsoft IME space, number, and alphabet input mode registry values to zero. The IME process is not restarted. The input behavior, reload requirement, and persistence still require verification on supported Windows 11 Home and Pro builds.

    .EXAMPLE
    Set-WUJapaneseImeHalfWidthInput

    Configures the three Microsoft IME input modes for half-width input.

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

    $shouldProcessParameters = Select-WUBoundParameter -BoundParameters $PSBoundParameters -Name 'WhatIf', 'Confirm'
    Set-WURegistrySetting -Name 'JapaneseImeHalfWidthInput' -Option 'Set' @shouldProcessParameters
}
