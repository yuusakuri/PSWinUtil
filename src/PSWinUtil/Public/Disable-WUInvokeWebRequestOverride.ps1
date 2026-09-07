function Disable-WUInvokeWebRequestOverride {
    <#
    .SYNOPSIS
    Disables the Invoke-WebRequest override.

    .DESCRIPTION
    Makes the Invoke-WebRequest proxy delegate to Microsoft.PowerShell.Utility Invoke-WebRequest without the PSWinUtil behavior in the current PowerShell session. Progress rendering follows the caller ProgressPreference value during the delegated request. The parameters of Invoke-WebRequest and the other command overrides are not changed, and another PowerShell session keeps its own state.

    .EXAMPLE
    Disable-WUInvokeWebRequestOverride

    Uses the original Invoke-WebRequest behavior in the current PowerShell session.

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
    Set-WUCommandOverrideState -Name 'Invoke-WebRequest' -Option 'Disable' @shouldProcessParameters
}
