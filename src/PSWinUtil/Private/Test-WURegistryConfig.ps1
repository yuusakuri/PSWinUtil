function Test-WURegistryConfig {
    <#
    .SYNOPSIS
    Tests registry config data.

    .DESCRIPTION
    Tests the Configs, Targets, Properties, and Options hierarchy, including unique names, supported scopes and registry hives, registry value types, option actions, and consistent option names.

    .PARAMETER Config
    Specifies imported registry config data to test.

    .EXAMPLE
    Test-WURegistryConfig -Config $registryConfig

    Returns true when the complete registry config data structure is valid.

    .INPUTS
    None

    .OUTPUTS
    System.Boolean
    #>
    [CmdletBinding()]
    [OutputType([bool])]
    param(
        [Parameter(Mandatory = $true)]
        [AllowNull()]
        [object]$Config
    )

    if (
        $Config -isnot [System.Collections.Hashtable] -or
        $Config.Count -ne 1 -or
        -not $Config.ContainsKey('Configs')
    ) {
        return $false
    }

    $configs = @($Config.Configs)
    if ($configs.Count -eq 0) {
        return $false
    }

    $configNames = @()
    $valueTypes = @{
        String = @([string])
        ExpandString = @([string])
        Binary = @([byte[]])
        DWord = @([byte], [int16], [int], [long], [uint16], [uint32])
        MultiString = @([string[]])
        QWord = @([byte], [int16], [int], [long], [uint16], [uint32], [uint64])
    }
    foreach ($configDefinition in $configs) {
        if (
            $configDefinition -isnot [System.Collections.Hashtable] -or
            $configDefinition.Count -ne 2 -or
            -not $configDefinition.ContainsKey('Name') -or
            -not $configDefinition.ContainsKey('Targets') -or
            $configDefinition.Name -isnot [string] -or
            [string]::IsNullOrWhiteSpace($configDefinition.Name) -or
            $configDefinition.Name -in $configNames
        ) {
            return $false
        }
        $configNames += $configDefinition.Name

        $targets = @($configDefinition.Targets)
        if ($targets.Count -eq 0) {
            return $false
        }

        $targetScopes = @()
        $configOptionNames = $null
        foreach ($target in $targets) {
            if (-not (Test-WURegistryConfigTarget -Target $target -ExistingScope $targetScopes -ValueTypes $valueTypes)) {
                return $false
            }

            $targetScopes += $target.Scope
            $targetOptionNames = @($target.Properties[0].Options.Name | Sort-Object)
            if ($null -ne $configOptionNames -and
                @(Compare-Object -ReferenceObject $configOptionNames -DifferenceObject $targetOptionNames).Count -gt 0) {
                return $false
            }
            $configOptionNames = $targetOptionNames
        }
    }

    $true
}
