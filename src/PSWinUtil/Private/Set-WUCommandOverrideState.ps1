function Set-WUCommandOverrideState {
    <#
    .SYNOPSIS
    Applies an override state to one command.

    .DESCRIPTION
    Records whether the proxy function of an overridden command applies its PSWinUtil behavior in the current PowerShell session. Each command is recorded on its own, so one change never affects another command.

    .PARAMETER Name
    Specifies an overridden command name.

    .PARAMETER Option
    Specifies Enable or Disable.

    .EXAMPLE
    Set-WUCommandOverrideState -Name 'Get-Content' -Option 'Disable'

    Makes the Get-Content proxy delegate to the original cmdlet without changing its defaults.

    .INPUTS
    None

    .OUTPUTS
    None
    #>
    [CmdletBinding(SupportsShouldProcess = $true)]
    param(
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$Name,

        [Parameter(Mandatory = $true)]
        [ValidateSet('Enable', 'Disable')]
        [string]$Option
    )

    if ($Name -notin @(Get-WUCommandOverrideName)) {
        throw "The command override was not found: $Name"
    }
    if (-not $PSCmdlet.ShouldProcess('Current PowerShell session', "$Option the $Name override")) {
        return
    }

    $stateVariable = Get-Variable -Name 'WUCommandOverrideState' -Scope Script -ErrorAction Ignore
    if ($null -eq $stateVariable -or $null -eq $stateVariable.Value) {
        $script:WUCommandOverrideState = @{}
    }
    $script:WUCommandOverrideState[$Name] = $Option -eq 'Enable'
}
