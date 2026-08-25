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

    $selectedScopes = @($Scope | Select-Object -Unique)
    if ($selectedScopes.Count -gt 1 -and $selectedScopes -contains 'Auto') {
        throw 'Auto cannot be combined with another scope.'
    }

    $settingData = Import-WURegistrySetting
    if (-not $settingData.ContainsKey($Name)) {
        throw "The registry setting was not found: $Name"
    }

    $shouldProcessParameters = Select-WUBoundParameter `
        -BoundParameters $PSBoundParameters `
        -Name 'WhatIf', 'Confirm'

    foreach ($currentScope in $selectedScopes) {
        $selection = Get-WURegistrySettingCandidate `
            -Setting $settingData[$Name] `
            -Scope $currentScope
        $firstCandidate = $selection.Properties[0].Candidate
        if (-not $firstCandidate.Options.ContainsKey($Option)) {
            throw "The registry setting option was not found: $Name/$Option"
        }

        $currentState = Get-WURegistrySetting -Name $Name -Scope $selection.Scope
        if ($currentState.State -ceq $Option) {
            continue
        }

        foreach ($selectedProperty in $selection.Properties) {
            $candidate = $selectedProperty.Candidate
            $selectedOption = $candidate.Options[$Option]
            if ($selectedOption.Action -eq 'Remove') {
                Remove-WURegistryProperty `
                    -Path $candidate.Path `
                    -Name $candidate.Name `
                    @shouldProcessParameters
            } else {
                Set-WURegistryProperty `
                    -Path $candidate.Path `
                    -Name $candidate.Name `
                    -Value $selectedOption.Value `
                    -Type $candidate.Type `
                    @shouldProcessParameters
            }
        }
    }
}
