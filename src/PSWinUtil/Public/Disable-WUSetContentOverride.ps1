function Disable-WUSetContentOverride {
    <#
    .SYNOPSIS
    Disables the Set-Content override.

    .DESCRIPTION
    Makes the Set-Content proxy delegate to Microsoft.PowerShell.Management Set-Content without the PSWinUtil behavior in the current PowerShell session. File content is written with the original cmdlet encoding default and line separators when Encoding is omitted. The parameters of Set-Content and the other command overrides are not changed, and another PowerShell session keeps its own state.

    .EXAMPLE
    Disable-WUSetContentOverride

    Uses the original Set-Content behavior in the current PowerShell session.

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
    Set-WUCommandOverrideState -Name 'Set-Content' -Option 'Disable' @shouldProcessParameters
}
