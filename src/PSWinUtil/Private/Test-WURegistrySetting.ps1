function Test-WURegistrySetting {
    <#
    .SYNOPSIS
    Tests registry setting data.

    .DESCRIPTION
    Tests setting names, property definitions, option property references, supported registry hives, registry value types, option actions, and complete User or Machine candidate sets.

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

    if ($Setting -isnot [System.Collections.Hashtable] -or $Setting.Count -eq 0) {
        return $false
    }

    $supportedTypes = @('String', 'ExpandString', 'Binary', 'DWord', 'MultiString', 'QWord')
    foreach ($settingEntry in $Setting.GetEnumerator()) {
        if (
            $settingEntry.Key -isnot [string] -or
            [string]::IsNullOrWhiteSpace($settingEntry.Key) -or
            $settingEntry.Value -isnot [System.Collections.Hashtable] -or
            $settingEntry.Value.Count -eq 0
        ) {
            return $false
        }

        $setting = $settingEntry.Value
        if (
            $setting.Count -ne 2 -or
            -not $setting.ContainsKey('Properties') -or
            -not $setting.ContainsKey('Options') -or
            $setting.Properties -isnot [System.Collections.Hashtable] -or
            $setting.Properties.Count -eq 0 -or
            $setting.Options -isnot [System.Collections.Hashtable] -or
            $setting.Options.Count -eq 0
        ) {
            return $false
        }

        $completeScopes = @('User', 'Machine')
        foreach ($propertyEntry in $setting.Properties.GetEnumerator()) {
            if (
                $propertyEntry.Key -isnot [string] -or
                [string]::IsNullOrWhiteSpace($propertyEntry.Key)
            ) {
                return $false
            }

            $candidates = @($propertyEntry.Value)
            if ($candidates.Count -eq 0) {
                return $false
            }

            $candidateScopes = @()
            foreach ($candidate in $candidates) {
                if (
                    $candidate -isnot [System.Collections.Hashtable] -or
                    $candidate.Count -ne 2 -or
                    -not $candidate.ContainsKey('Path') -or
                    -not $candidate.ContainsKey('Type') -or
                    $candidate.Path -isnot [string] -or
                    [string]::IsNullOrWhiteSpace($candidate.Path) -or
                    $candidate.Type -notin $supportedTypes
                ) {
                    return $false
                }

                $candidateScope = $null
                if ($candidate.Path -match '^Registry::HKEY_CURRENT_USER\\.+') {
                    $candidateScope = 'User'
                } elseif ($candidate.Path -match '^Registry::HKEY_(LOCAL_MACHINE|CURRENT_CONFIG)\\.+') {
                    $candidateScope = 'Machine'
                } else {
                    return $false
                }
                if ($candidateScope -in $candidateScopes) {
                    return $false
                }
                $candidateScopes += $candidateScope
            }

            $completeScopes = @($completeScopes | Where-Object { $_ -in $candidateScopes })
        }

        if ($completeScopes.Count -eq 0) {
            return $false
        }

        foreach ($optionEntry in $setting.Options.GetEnumerator()) {
            if (
                $optionEntry.Key -isnot [string] -or
                [string]::IsNullOrWhiteSpace($optionEntry.Key) -or
                $optionEntry.Value -isnot [System.Collections.Hashtable] -or
                $optionEntry.Value.Count -ne $setting.Properties.Count
            ) {
                return $false
            }

            foreach ($propertyEntry in $setting.Properties.GetEnumerator()) {
                $propertyName = [string]$propertyEntry.Key
                if (-not $optionEntry.Value.ContainsKey($propertyName)) {
                    return $false
                }

                $change = $optionEntry.Value[$propertyName]
                if (
                    $change -isnot [System.Collections.Hashtable] -or
                    -not $change.ContainsKey('Action') -or
                    $change.Action -notin @('Set', 'Remove')
                ) {
                    return $false
                }

                if ($change.Action -eq 'Remove') {
                    if ($change.Count -ne 1) {
                        return $false
                    }
                    continue
                }

                if (
                    $change.Count -ne 2 -or
                    -not $change.ContainsKey('Value') -or
                    $null -eq $change.Value
                ) {
                    return $false
                }

                foreach ($candidate in @($propertyEntry.Value)) {
                    $settingValue = $change.Value
                    $valueIsValid = switch ($candidate.Type) {
                        'String' { $settingValue -is [string]; break }
                        'ExpandString' { $settingValue -is [string]; break }
                        'Binary' { $settingValue -is [byte[]]; break }
                        'DWord' {
                            $settingValue -is [byte] -or
                            $settingValue -is [int16] -or
                            $settingValue -is [int] -or
                            $settingValue -is [long] -or
                            $settingValue -is [uint16] -or
                            $settingValue -is [uint32]
                            break
                        }
                        'MultiString' {
                            $settingValue -is [string[]]
                            break
                        }
                        'QWord' {
                            $settingValue -is [byte] -or
                            $settingValue -is [int16] -or
                            $settingValue -is [int] -or
                            $settingValue -is [long] -or
                            $settingValue -is [uint16] -or
                            $settingValue -is [uint32] -or
                            $settingValue -is [uint64]
                            break
                        }
                    }
                    if (-not $valueIsValid) {
                        return $false
                    }
                }
            }
        }
    }

    $true
}
