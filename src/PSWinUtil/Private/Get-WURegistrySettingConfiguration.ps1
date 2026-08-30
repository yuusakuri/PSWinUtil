function Get-WURegistrySettingConfiguration {
    <#
    .SYNOPSIS
    Selects a registry setting configuration.

    .DESCRIPTION
    Selects one configuration from a validated registry setting. Auto uses the User configuration before the Machine configuration.

    .PARAMETER Setting
    Specifies one validated registry setting definition.

    .PARAMETER Scope
    Specifies Auto, User, or Machine.

    .EXAMPLE
    Get-WURegistrySettingConfiguration -Setting $setting -Scope Auto

    Selects a configuration and returns its resolved scope.

    .INPUTS
    None

    .OUTPUTS
    System.Collections.Hashtable
    #>
    [CmdletBinding()]
    [OutputType([System.Collections.Hashtable])]
    param(
        [Parameter(Mandatory = $true)]
        [System.Collections.Hashtable]$Setting,

        [Parameter(Mandatory = $true)]
        [ValidateSet('Auto', 'User', 'Machine')]
        [string]$Scope
    )

    $targetScopes = if ($Scope -eq 'Auto') { @('User', 'Machine') } else { @($Scope) }

    foreach ($targetScope in $targetScopes) {
        $configuration = @(
            $Setting.Configurations | Where-Object { $_.Scope -ceq $targetScope }
        )[0]
        if ($null -ne $configuration) {
            return $configuration
        }
    }

    throw "The registry setting does not support the requested scope: $Scope"
}
