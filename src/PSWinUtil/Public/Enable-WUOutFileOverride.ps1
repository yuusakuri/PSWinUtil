function Enable-WUOutFileOverride {
    <#
    .SYNOPSIS
    Enables the Out-File override.

    .DESCRIPTION
    Applies the PSWinUtil Out-File behavior in the current PowerShell session. Formatted output is written as UTF-8 without a byte order mark and with LF when Encoding is omitted or UTF8 is specified. The parameters of Out-File and the other command overrides are not changed, and another PowerShell session keeps its own state.

    .EXAMPLE
    Enable-WUOutFileOverride

    Uses the PSWinUtil Out-File behavior in the current PowerShell session.

    .INPUTS
    None

    .OUTPUTS
    None
    #>
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute(
        'PSShouldProcess',
        '',
        Justification = 'The override state command evaluates ShouldProcess for the delegated change.'
    )]
    [CmdletBinding(SupportsShouldProcess = $true)]
    param()

    $shouldProcessParameters = Select-WUBoundParameter -BoundParameters $PSBoundParameters -Name 'WhatIf', 'Confirm'
    Set-WUCommandOverrideState -Name 'Out-File' -Option 'Enable' @shouldProcessParameters
}
