function Enable-WUInvokeWebRequestOverride {
    <#
    .SYNOPSIS
    Enables the Invoke-WebRequest override.

    .DESCRIPTION
    Applies the PSWinUtil Invoke-WebRequest behavior in the current PowerShell session. Progress rendering is suppressed during the delegated request to avoid its substantial Windows PowerShell performance cost. The parameters of Invoke-WebRequest and the other command overrides are not changed, and another PowerShell session keeps its own state.

    .EXAMPLE
    Enable-WUInvokeWebRequestOverride

    Uses the PSWinUtil Invoke-WebRequest behavior in the current PowerShell session.

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
    Set-WUCommandOverrideState -Name 'Invoke-WebRequest' -Option 'Enable' @shouldProcessParameters
}
