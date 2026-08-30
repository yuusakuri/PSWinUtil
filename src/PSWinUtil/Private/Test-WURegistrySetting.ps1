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
            if (
                $configuration -isnot [System.Collections.Hashtable] -or
                $configuration.Count -ne 2 -or
                -not $configuration.ContainsKey('Scope') -or
                -not $configuration.ContainsKey('Properties') -or
                $configuration.Scope -notin @('User', 'Machine') -or
                $configuration.Scope -in $configurationScopes
            ) {
                return $false
            }
            $configurationScopes += $configuration.Scope

            $properties = @($configuration.Properties)
            if ($properties.Count -eq 0) {
                return $false
            }

            $propertyNames = @()
            $configurationOptionNames = $null
            foreach ($property in $properties) {
                if (
                    $property -isnot [System.Collections.Hashtable] -or
                    $property.Count -ne 4 -or
                    -not $property.ContainsKey('Name') -or
                    -not $property.ContainsKey('Path') -or
                    -not $property.ContainsKey('Type') -or
                    -not $property.ContainsKey('Options') -or
                    $property.Name -isnot [string] -or
                    [string]::IsNullOrWhiteSpace($property.Name) -or
                    $property.Name -in $propertyNames -or
                    $property.Path -isnot [string] -or
                    [string]::IsNullOrWhiteSpace($property.Path) -or
                    $property.Type -notin $valueTypes.Keys
                ) {
                    return $false
                }
                $propertyNames += $property.Name

                if ($configuration.Scope -eq 'User') {
                    if ($property.Path -notmatch '^Registry::HKEY_CURRENT_USER\\.+') {
                        return $false
                    }
                } elseif ($property.Path -notmatch '^Registry::HKEY_(LOCAL_MACHINE|CURRENT_CONFIG)\\.+') {
                    return $false
                }

                $options = @($property.Options)
                if ($options.Count -eq 0) {
                    return $false
                }

                $optionNames = @()
                foreach ($option in $options) {
                    if (
                        $option -isnot [System.Collections.Hashtable] -or
                        -not $option.ContainsKey('Name') -or
                        -not $option.ContainsKey('Action') -or
                        $option.Name -isnot [string] -or
                        [string]::IsNullOrWhiteSpace($option.Name) -or
                        $option.Name -in $optionNames -or
                        $option.Action -notin @('Set', 'Remove')
                    ) {
                        return $false
                    }
                    $optionNames += $option.Name

                    if ($option.Action -eq 'Remove') {
                        if ($option.Count -ne 2) {
                            return $false
                        }
                        continue
                    }

                    if (
                        $option.Count -ne 3 -or
                        -not $option.ContainsKey('Value') -or
                        $null -eq $option.Value
                    ) {
                        return $false
                    }

                    $valueIsValid = $false
                    foreach ($valueType in $valueTypes[$property.Type]) {
                        if ($valueType.IsInstanceOfType($option.Value)) {
                            $valueIsValid = $true
                            break
                        }
                    }
                    if (-not $valueIsValid) {
                        return $false
                    }
                }

                $optionNames = @($optionNames | Sort-Object)
                if ($null -eq $configurationOptionNames) {
                    $configurationOptionNames = $optionNames
                } elseif (@(Compare-Object -ReferenceObject $configurationOptionNames -DifferenceObject $optionNames).Count -gt 0) {
                    return $false
                }
            }

            if ($null -eq $settingOptionNames) {
                $settingOptionNames = $configurationOptionNames
            } elseif (@(Compare-Object -ReferenceObject $settingOptionNames -DifferenceObject $configurationOptionNames).Count -gt 0) {
                return $false
            }
        }
    }

    $true
}
