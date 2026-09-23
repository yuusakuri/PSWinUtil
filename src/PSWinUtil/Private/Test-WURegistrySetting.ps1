function Test-WURegistrySetting {
    <#
    .SYNOPSIS
    Tests registry setting data.

    .DESCRIPTION
    Tests the Settings, Configurations, Properties, and Options hierarchy, including unique names, supported scopes and registry hives, registry value types, option actions, and consistent option names.

    .PARAMETER Setting
    Specifies imported registry setting data to test.

    .EXAMPLE
    Test-WURegistrySetting -Setting $settingData

    Returns true when the complete registry setting data structure is valid.

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
        [object]$Setting
    )

    if (
        $Setting -isnot [System.Collections.Hashtable] -or
        $Setting.Count -ne 1 -or
        -not $Setting.ContainsKey('Settings')
    ) {
        return $false
    }

    $settings = @($Setting.Settings)
    if ($settings.Count -eq 0) {
        return $false
    }

    $settingNames = @()
    $valueTypes = @{
        String = @([string])
        ExpandString = @([string])
        Binary = @([byte[]])
        DWord = @([byte], [int16], [int], [long], [uint16], [uint32])
        MultiString = @([string[]])
        QWord = @([byte], [int16], [int], [long], [uint16], [uint32], [uint64])
    }
    foreach ($settingDefinition in $settings) {
        if (
            $settingDefinition -isnot [System.Collections.Hashtable] -or
            $settingDefinition.Count -ne 2 -or
            -not $settingDefinition.ContainsKey('Name') -or
            -not $settingDefinition.ContainsKey('Configurations') -or
            $settingDefinition.Name -isnot [string] -or
            [string]::IsNullOrWhiteSpace($settingDefinition.Name) -or
            $settingDefinition.Name -in $settingNames
        ) {
            return $false
        }
        $settingNames += $settingDefinition.Name

        $configurations = @($settingDefinition.Configurations)
        if ($configurations.Count -eq 0) {
            return $false
        }

        $configurationScopes = @()
        $settingOptionNames = $null
        foreach ($configuration in $configurations) {
            $result = Test-WURegistryConfiguration -Configuration $configuration -ExistingScope $configurationScopes -ValueTypes $valueTypes
            if ($null -eq $result) {
                return $false
            }

            $configurationScopes += $result.Scope
            if ($null -ne $settingOptionNames -and
                @(Compare-Object -ReferenceObject $settingOptionNames -DifferenceObject $result.OptionNames).Count -gt 0) {
                return $false
            }
            $settingOptionNames = $result.OptionNames
        }
    }

    $true
}
