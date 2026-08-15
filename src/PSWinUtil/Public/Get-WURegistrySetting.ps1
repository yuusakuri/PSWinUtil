function Get-WURegistrySetting {
    <#
    .SYNOPSIS
    Gets a Windows registry setting state.

    .DESCRIPTION
    Gets the state of a named registry setting. Auto selects a complete User candidate set before a complete Machine candidate set. The result is an option name, NotConfigured, or Mixed.

    .PARAMETER Name
    Specifies one or more registry setting names from the distributed setting data.

    .PARAMETER Scope
    Specifies Auto, User, or Machine. The default value is Auto.

    .EXAMPLE
    Get-WURegistrySetting -Name 'DarkMode' -Scope User

    Gets the current DarkMode setting state for the current user.

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
        [string]$Scope = 'Auto'
    )

    begin {
        $settingData = Import-WURegistrySetting
    }

    process {
        foreach ($currentName in $Name) {
            if (-not $settingData.ContainsKey($currentName)) {
                throw "The registry setting was not found: $currentName"
            }

            $selection = Get-WURegistrySettingCandidate `
                -Setting $settingData[$currentName] `
                -Scope $Scope
            $propertyStates = @()
            foreach ($selectedProperty in $selection.Properties) {
                $candidate = $selectedProperty.Candidate
                $registryProperty = Get-WURegistryProperty `
                    -Path $candidate.Path `
                    -Name $candidate.Name
                $propertyStates += [pscustomobject]@{
                    Candidate = $candidate
                    RegistryProperty = $registryProperty
                }
            }

            $firstCandidate = $selection.Properties[0].Candidate
            $state = $null
            foreach ($optionName in @($firstCandidate.Options.Keys | Sort-Object)) {
                $optionMatches = $true
                foreach ($propertyState in $propertyStates) {
                    $option = $propertyState.Candidate.Options[$optionName]
                    if ($option.Action -eq 'Remove') {
                        if ($null -ne $propertyState.RegistryProperty) {
                            $optionMatches = $false
                            break
                        }
                    } elseif (
                        $null -eq $propertyState.RegistryProperty -or
                        $propertyState.RegistryProperty.Type -ine $propertyState.Candidate.Type -or
                        -not (Compare-WURegistryValue `
                                -ReferenceValue $option.Value `
                                -DifferenceValue $propertyState.RegistryProperty.Value)
                    ) {
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
                Name = $currentName
                Scope = $selection.Scope
                State = $state
            }
        }
    }
}
