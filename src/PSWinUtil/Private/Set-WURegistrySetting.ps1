function Set-WURegistrySetting {
    <#
    .SYNOPSIS
    Applies a registry setting option.

    .DESCRIPTION
    Resolves the selected option into registry property changes for one or more scopes and delegates every change to Set-WURegistryProperty or Remove-WURegistryProperty.

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

    $settingData = Import-WURegistrySetting
    if (-not $settingData.ContainsKey($Name)) {
        throw "The registry setting was not found: $Name"
    }
    $setting = $settingData[$Name]

    $shouldProcessParameters = Select-WUBoundParameter -BoundParameters $PSBoundParameters -Name 'WhatIf', 'Confirm'

    foreach ($targetScope in $scopes) {
        $selectionParameters = @{
            Setting = $setting
            Scope = $targetScope
        }
        $selection = Get-WURegistrySettingCandidate @selectionParameters
        if (-not $setting.Options.ContainsKey($Option)) {
            throw "The registry setting option was not found: $Name/$Option"
        }

        $currentState = Get-WURegistrySetting -Name $Name -Scope $selection.Scope
        if ($currentState.State -ceq $Option) {
            continue
        }

        $changes = $setting.Options[$Option]
        foreach ($propertySelection in $selection.Properties) {
            $candidate = $propertySelection.Candidate
            $change = $changes[$propertySelection.Name]
            $propertyParameters = @{
                Path = $candidate.Path
                Name = $propertySelection.Name
            }
            if ($change.Action -eq 'Remove') {
                Remove-WURegistryProperty @propertyParameters @shouldProcessParameters
            } else {
                $propertyParameters.Value = $change.Value
                $propertyParameters.Type = $candidate.Type
                Set-WURegistryProperty @propertyParameters @shouldProcessParameters
            }
        }
    }
}
