function Get-WURegistrySetting {
    <#
    .SYNOPSIS
    Gets a Windows registry setting state.

    .DESCRIPTION
    Gets the state of a named registry setting in one or more scopes. Auto selects a complete User candidate set before a complete Machine candidate set. The result is an option name, NotConfigured, or Mixed.

    .PARAMETER Name
    Specifies one or more registry setting names from the distributed setting data.

    .PARAMETER Scope
    Specifies one or more of Auto, User, and Machine. Auto cannot be combined with another scope. The default value is Auto.

    .EXAMPLE
    Get-WURegistrySetting -Name 'DarkMode' -Scope User

    Gets the current DarkMode setting state for the current user.

    .EXAMPLE
    Get-WURegistrySetting -Name 'DarkMode' -Scope User, Machine

    Gets the current DarkMode setting state for the User and Machine scopes.

    .INPUTS
    System.String

    .OUTPUTS
    System.Management.Automation.PSCustomObject
    #>
    [CmdletBinding()]
    param(
        [Parameter(
            Mandatory = $true,
            Position = 0,
            ValueFromPipeline = $true,
            ValueFromPipelineByPropertyName = $true
        )]
        [ValidateNotNullOrEmpty()]
        [string[]]$Name,

        [Parameter()]
        [ValidateSet('Auto', 'User', 'Machine')]
        [string[]]$Scope = 'Auto'
    )

    begin {
        $scopes = @($Scope | Select-Object -Unique)
        if ($scopes.Count -gt 1 -and $scopes -contains 'Auto') {
            throw 'Auto cannot be combined with another scope.'
        }
        $settingData = Import-WURegistrySetting
    }

    process {
        foreach ($inputName in $Name) {
            if (-not $settingData.ContainsKey($inputName)) {
                throw "The registry setting was not found: $inputName"
            }
            $setting = $settingData[$inputName]

            foreach ($targetScope in $scopes) {
                $selectionParameters = @{
                    Setting = $setting
                    Scope = $targetScope
                }
                $selection = Get-WURegistrySettingCandidate @selectionParameters
                $propertyStates = @()
                foreach ($propertySelection in $selection.Properties) {
                    $candidate = $propertySelection.Candidate
                    $propertyParameters = @{
                        Path = $candidate.Path
                        Name = $propertySelection.Name
                    }
                    $registryProperty = Get-WURegistryProperty @propertyParameters
                    $propertyStates += [pscustomobject]@{
                        Name = $propertySelection.Name
                        Candidate = $candidate
                        RegistryProperty = $registryProperty
                    }
                }

                $state = $null
                foreach ($optionName in @($setting.Options.Keys | Sort-Object)) {
                    $changes = $setting.Options[$optionName]
                    $optionMatches = $true
                    foreach ($propertyState in $propertyStates) {
                        $change = $changes[$propertyState.Name]
                        if ($change.Action -eq 'Remove') {
                            if ($null -ne $propertyState.RegistryProperty) {
                                $optionMatches = $false
                                break
                            }
                            continue
                        }

                        if (
                            $null -eq $propertyState.RegistryProperty -or
                            $propertyState.RegistryProperty.Type -ine $propertyState.Candidate.Type
                        ) {
                            $optionMatches = $false
                            break
                        }

                        $comparisonParameters = @{
                            ReferenceValue = $change.Value
                            DifferenceValue = $propertyState.RegistryProperty.Value
                        }
                        if (-not (Compare-WURegistryValue @comparisonParameters)) {
                            $optionMatches = $false
                            break
                        }
                    }

                    if ($optionMatches) {
                        $state = [string]$optionName
                        break
                    }
                }

                if ($null -eq $state) {
                    $configuredPropertyCount = @(
                        $propertyStates | Where-Object { $null -ne $_.RegistryProperty }
                    ).Count
                    if ($configuredPropertyCount -eq 0) {
                        $state = 'NotConfigured'
                    } else {
                        $state = 'Mixed'
                    }
                }

                [pscustomobject]@{
                    PSTypeName = 'PSWinUtil.RegistrySetting'
                    Name = $inputName
                    Scope = $selection.Scope
                    State = $state
                }
            }
        }
    }
}
