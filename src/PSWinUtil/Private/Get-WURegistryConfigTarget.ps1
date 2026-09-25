function Get-WURegistryConfigTarget {
    <#
    .SYNOPSIS
    Selects a registry config target.

    .DESCRIPTION
    Selects one target from a validated registry config. Auto uses the User target before the Machine target.

    .PARAMETER Config
    Specifies one validated registry config definition.

    .PARAMETER Scope
    Specifies Auto, User, or Machine.

    .EXAMPLE
    Get-WURegistryConfigTarget -Config $registryConfig -Scope Auto

    Selects a target and returns its resolved scope.

    .INPUTS
    None

    .OUTPUTS
    System.Collections.Hashtable
    #>
    [CmdletBinding()]
    [OutputType([System.Collections.Hashtable])]
    param(
        [Parameter(Mandatory = $true)]
        [System.Collections.Hashtable]$Config,

        [Parameter(Mandatory = $true)]
        [ValidateSet('Auto', 'User', 'Machine')]
        [string]$Scope
    )

    $targetScopes = if ($Scope -eq 'Auto') { @('User', 'Machine') } else { @($Scope) }

    foreach ($targetScope in $targetScopes) {
        $target = @(
            $Config.Targets | Where-Object { $_.Scope -ceq $targetScope }
        )[0]
        if ($null -ne $target) {
            return $target
        }
    }

    throw "The registry config does not support the requested scope: $Scope"
}
