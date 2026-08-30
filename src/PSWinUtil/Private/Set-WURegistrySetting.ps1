function Set-WURegistrySetting {
    <#
    .SYNOPSIS
    Applies a registry setting option.

    .DESCRIPTION
    Selects a configuration for each requested scope, resolves the selected option from every property, and delegates each change to Set-WURegistryProperty or Remove-WURegistryProperty.

    .PARAMETER Name
    Specifies a registry setting name from the distributed setting data.

    .PARAMETER Option
    Specifies an option defined for the registry setting.

    .PARAMETER Scope
    Specifies one or more of Auto, User, and Machine. Auto cannot be combined with another scope. The default value is Auto.

    .EXAMPLE
    Set-WURegistrySetting -Name 'DarkMode' -Option 'Enable' -Scope User

    Applies the Enable option for the current user's DarkMode setting.

    .EXAMPLE
    Set-WURegistrySetting -Name 'DarkMode' -Option 'Enable' -Scope User, Machine

    Applies the Enable option to the User and Machine scopes.

    .INPUTS
    None

    .OUTPUTS
    None
    #>
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute(
        'PSShouldProcess',
        '',
        Justification = 'Registry property commands evaluate ShouldProcess for each delegated change.'
    )]
    [CmdletBinding(SupportsShouldProcess = $true)]
    param(
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$Name,

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$Option,

        [Parameter()]
        [ValidateSet('Auto', 'User', 'Machine')]
        [string[]]$Scope = 'Auto'
    )

    $scopes = @($Scope | Select-Object -Unique)
    if ($scopes.Count -gt 1 -and $scopes -contains 'Auto') {
        throw 'Auto cannot be combined with another scope.'
    }

    $settings = @((Import-WURegistrySetting).Settings)
    $setting = @($settings | Where-Object { $_.Name -ieq $Name })[0]
    if ($null -eq $setting) {
        throw "The registry setting was not found: $Name"
    }

    $shouldProcessParameters = Select-WUBoundParameter -BoundParameters $PSBoundParameters -Name 'WhatIf', 'Confirm'

    foreach ($targetScope in $scopes) {
        $configurationParameters = @{
            Setting = $setting
            Scope = $targetScope
        }
        $configuration = Get-WURegistrySettingConfiguration @configurationParameters
        $configurationOption = @(
            $configuration.Properties[0].Options | Where-Object { $_.Name -ieq $Option }
        )[0]
        if ($null -eq $configurationOption) {
            throw "The registry setting option was not found: $Name/$Option"
        }

        $currentState = Get-WURegistrySetting -Name $Name -Scope $configuration.Scope
        if ($currentState.State -ceq $configurationOption.Name) {
            continue
        }

        foreach ($property in $configuration.Properties) {
            $propertyOption = @($property.Options | Where-Object { $_.Name -ieq $Option })[0]
            $propertyParameters = @{
                Path = $property.Path
                Name = $property.Name
            }
            if ($propertyOption.Action -eq 'Remove') {
                Remove-WURegistryProperty @propertyParameters @shouldProcessParameters
            } else {
                $propertyParameters.Value = $propertyOption.Value
                $propertyParameters.Type = $property.Type
                Set-WURegistryProperty @propertyParameters @shouldProcessParameters
            }
        }
    }
}
