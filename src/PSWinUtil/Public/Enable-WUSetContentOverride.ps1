function Enable-WUSetContentOverride {
    <#
    .SYNOPSIS
    Enables the Set-Content override.

    .DESCRIPTION
    Applies the PSWinUtil Set-Content behavior in the current PowerShell session. File content is written as UTF-8 without a byte order mark and with LF when Encoding is omitted or UTF8 is specified. The parameters of Set-Content and the other command overrides are not changed, and another PowerShell session keeps its own state.

    .EXAMPLE
    Enable-WUSetContentOverride

    Uses the PSWinUtil Set-Content behavior in the current PowerShell session.

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
    Set-WUCommandOverrideState -Name 'Set-Content' -Option 'Enable' @shouldProcessParameters
}
