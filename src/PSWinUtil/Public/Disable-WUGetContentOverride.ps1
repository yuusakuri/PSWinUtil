function Disable-WUGetContentOverride {
    <#
    .SYNOPSIS
    Disables the Get-Content override.

    .DESCRIPTION
    Makes the Get-Content proxy delegate to Microsoft.PowerShell.Management Get-Content without the PSWinUtil behavior in the current PowerShell session. File system text is decoded with the original cmdlet encoding default when Encoding is omitted. The parameters of Get-Content and the other command overrides are not changed, and another PowerShell session keeps its own state.

    .EXAMPLE
    Disable-WUGetContentOverride

    Uses the original Get-Content behavior in the current PowerShell session.

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
    Set-WUCommandOverrideState -Name 'Get-Content' -Option 'Disable' @shouldProcessParameters
}
