function Test-WUCommandOverrideEnabled {
    <#
    .SYNOPSIS
    Tests whether a command override is enabled.

    .DESCRIPTION
    Reads the override state recorded for the current PowerShell session. A command whose state was never changed is reported as enabled, so every proxy function keeps its PSWinUtil behavior until it is disabled.

    .PARAMETER Name
    Specifies an overridden command name.

    .EXAMPLE
    Test-WUCommandOverrideEnabled -Name 'Get-Content'

    Returns whether the Get-Content proxy applies its PSWinUtil behavior.

    .INPUTS
    None

    .OUTPUTS
    System.Boolean
    #>
    [CmdletBinding()]
    [OutputType([bool])]
    param(
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$Name
    )

    $stateVariable = Get-Variable -Name 'WUCommandOverrideState' -Scope Script -ErrorAction Ignore
    if ($null -eq $stateVariable -or $null -eq $stateVariable.Value) {
        return $true
    }
    if (-not $stateVariable.Value.ContainsKey($Name)) {
        return $true
    }

    [bool]$stateVariable.Value[$Name]
}
