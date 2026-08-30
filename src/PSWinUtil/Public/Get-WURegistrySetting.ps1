function Get-WURegistrySetting {
    <#
    .SYNOPSIS
    Gets a Windows registry setting state.

    .DESCRIPTION
    Gets the state of a named registry setting in one or more scopes. Auto selects the User configuration before the Machine configuration. The result is an option name, NotConfigured, or Mixed.

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
        $settings = @((Import-WURegistrySetting).Settings)
    }

    process {
        foreach ($inputName in $Name) {
            $setting = @($settings | Where-Object { $_.Name -ieq $inputName })[0]
            if ($null -eq $setting) {
                throw "The registry setting was not found: $inputName"
            }

            foreach ($targetScope in $scopes) {
                $configuration = Get-WURegistrySettingConfiguration -Setting $setting -Scope $targetScope
                $propertyStates = @(
                    foreach ($property in $configuration.Properties) {
                        $registryProperty = Get-WURegistryProperty -Path $property.Path -Name $property.Name
                        [pscustomobject]@{
                            Property = $property
                            RegistryProperty = $registryProperty
                        }
                    }
                )

                $state = $null
                foreach ($optionName in @($configuration.Properties[0].Options.Name | Sort-Object)) {
                    $optionMatches = $true
                    foreach ($propertyState in $propertyStates) {
                        $option = @(
                            $propertyState.Property.Options | Where-Object { $_.Name -ieq $optionName }
                        )[0]
                        if ($option.Action -eq 'Remove') {
                            if ($null -ne $propertyState.RegistryProperty) {
                                $optionMatches = $false
                                break
                            }
                            continue
                        }

                        if (
                            $null -eq $propertyState.RegistryProperty -or
                            $propertyState.RegistryProperty.Type -ine $propertyState.Property.Type
                        ) {
                            $optionMatches = $false
                            break
                        }

                        if (-not (Compare-WURegistryValue -ReferenceValue $option.Value -DifferenceValue $propertyState.RegistryProperty.Value)) {
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
                    Scope = $configuration.Scope
                    State = $state
                }
            }
        }
    }
}
