function Disable-WUOutFileOverride {
    <#
    .SYNOPSIS
    Disables the Out-File override.

    .DESCRIPTION
    Makes the Out-File proxy delegate to Microsoft.PowerShell.Utility Out-File without the PSWinUtil behavior in the current PowerShell session. Formatted output is written with the original cmdlet encoding default and line separators when Encoding is omitted. The parameters of Out-File and the other command overrides are not changed, and another PowerShell session keeps its own state.

    .EXAMPLE
    Disable-WUOutFileOverride

    Uses the original Out-File behavior in the current PowerShell session.

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
    Set-WUCommandOverrideState -Name 'Out-File' -Option 'Disable' @shouldProcessParameters
}
