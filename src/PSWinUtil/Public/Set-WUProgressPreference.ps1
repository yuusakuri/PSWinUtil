function Set-WUProgressPreference {
    <#
    .SYNOPSIS
    Sets the progress preference of the current PowerShell session.

    .DESCRIPTION
    Assigns the requested value to the global ProgressPreference variable, so every command in the current PowerShell session follows it. SilentlyContinue stops the progress bar, which removes the substantial rendering cost that Windows PowerShell 5.1 adds to commands such as Invoke-WebRequest. Assigning ProgressPreference inside a script reaches only that script and the commands it calls, so this command is the way to change the whole session at once.

    .PARAMETER Value
    Specifies a PowerShell action preference such as SilentlyContinue or Continue.

    .EXAMPLE
    Set-WUProgressPreference -Value SilentlyContinue

    Stops the progress bar for the current PowerShell session.

    .EXAMPLE
    Set-WUProgressPreference -Value Continue

    Shows the progress bar again for the current PowerShell session.

    .INPUTS
    None

    .OUTPUTS
    None
    #>
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute(
        'PSAvoidGlobalVars',
        '',
        Justification = 'PowerShell reads the session progress preference from the global ProgressPreference variable.'
    )]
    [CmdletBinding(SupportsShouldProcess = $true)]
    param(
        [Parameter(Mandatory = $true, Position = 0)]
        [System.Management.Automation.ActionPreference]$Value
    )

    if (-not $PSCmdlet.ShouldProcess('Current PowerShell session', "Set the progress preference to $Value")) {
        return
    }

    $global:ProgressPreference = $Value
}
