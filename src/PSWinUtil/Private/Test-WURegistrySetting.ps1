function Test-WURegistrySetting {
    <#
    .SYNOPSIS
    Tests registry setting data.

    .DESCRIPTION
    Tests setting names, property candidates, supported registry hives, registry value types, option actions, and complete User or Machine candidate sets.

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

        $expectedOptionNames = $null
        $completeScopes = @('User', 'Machine')
        foreach ($propertyEntry in $settingEntry.Value.GetEnumerator()) {
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
                    -not $candidate.ContainsKey('Path') -or
                    -not $candidate.ContainsKey('Name') -or
                    -not $candidate.ContainsKey('Type') -or
                    -not $candidate.ContainsKey('Options') -or
                    $candidate.Path -isnot [string] -or
                    $candidate.Name -isnot [string] -or
                    [string]::IsNullOrWhiteSpace($candidate.Name) -or
                    $candidate.Type -notin $supportedTypes -or
                    $candidate.Options -isnot [System.Collections.Hashtable] -or
                    $candidate.Options.Count -eq 0
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

                $optionNames = @($candidate.Options.Keys | Sort-Object)
                if ($null -eq $expectedOptionNames) {
                    $expectedOptionNames = $optionNames
                } elseif (@(Compare-Object -ReferenceObject $expectedOptionNames -DifferenceObject $optionNames).Count -gt 0) {
                    return $false
                }

                foreach ($optionEntry in $candidate.Options.GetEnumerator()) {
                    if (
                        $optionEntry.Key -isnot [string] -or
                        [string]::IsNullOrWhiteSpace($optionEntry.Key) -or
                        $optionEntry.Value -isnot [System.Collections.Hashtable] -or
                        -not $optionEntry.Value.ContainsKey('Action') -or
                        $optionEntry.Value.Action -notin @('Set', 'Remove')
                    ) {
                        return $false
                    }

                    if (
                        $optionEntry.Value.Action -eq 'Set' -and
                        (
                            -not $optionEntry.Value.ContainsKey('Value') -or
                            $null -eq $optionEntry.Value.Value
                        )
                    ) {
                        return $false
                    }

                    if ($optionEntry.Value.Action -eq 'Set') {
                        $settingValue = $optionEntry.Value.Value
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

            $completeScopes = @($completeScopes | Where-Object { $_ -in $candidateScopes })
        }

        if ($completeScopes.Count -eq 0) {
            return $false
        }
    }

    $true
}
