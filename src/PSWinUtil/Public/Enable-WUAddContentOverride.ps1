function Enable-WUAddContentOverride {
    <#
    .SYNOPSIS
    Enables the Add-Content override.

    .DESCRIPTION
    Applies the PSWinUtil Add-Content behavior in the current PowerShell session. Existing file content is converted to UTF-8 without a byte order mark and to LF, and appended content uses the same format, when Encoding is omitted or UTF8 is specified. The parameters of Add-Content and the other command overrides are not changed, and another PowerShell session keeps its own state.

    .EXAMPLE
    Enable-WUAddContentOverride

    Uses the PSWinUtil Add-Content behavior in the current PowerShell session.

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
    Set-WUCommandOverrideState -Name 'Add-Content' -Option 'Enable' @shouldProcessParameters
}
