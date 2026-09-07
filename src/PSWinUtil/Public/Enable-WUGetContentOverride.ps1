function Enable-WUGetContentOverride {
    <#
    .SYNOPSIS
    Enables the Get-Content override.

    .DESCRIPTION
    Applies the PSWinUtil Get-Content behavior in the current PowerShell session. File system text is decoded as UTF-8 when Encoding is omitted. The parameters of Get-Content and the other command overrides are not changed, and another PowerShell session keeps its own state.

    .EXAMPLE
    Enable-WUGetContentOverride

    Uses the PSWinUtil Get-Content behavior in the current PowerShell session.

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
    Set-WUCommandOverrideState -Name 'Get-Content' -Option 'Enable' @shouldProcessParameters
}
