function Disable-WUAddContentOverride {
    <#
    .SYNOPSIS
    Disables the Add-Content override.

    .DESCRIPTION
    Makes the Add-Content proxy delegate to Microsoft.PowerShell.Management Add-Content without the PSWinUtil behavior in the current PowerShell session. Existing file content is left as it is, and appended content uses the original cmdlet encoding default and line separators when Encoding is omitted. The parameters of Add-Content and the other command overrides are not changed, and another PowerShell session keeps its own state.

    .EXAMPLE
    Disable-WUAddContentOverride

    Uses the original Add-Content behavior in the current PowerShell session.

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
    Set-WUCommandOverrideState -Name 'Add-Content' -Option 'Disable' @shouldProcessParameters
}
