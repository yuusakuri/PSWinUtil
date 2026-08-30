function Get-WURegistrySettingCandidate {
    <#
    .SYNOPSIS
    Selects registry property candidates.

    .DESCRIPTION
    Selects one registry property candidate for every named property definition in a setting. Auto uses a complete User candidate set before a complete Machine candidate set.

    .PARAMETER Setting
    Specifies one validated registry setting definition.

    .PARAMETER Scope
    Specifies Auto, User, or Machine.

    .EXAMPLE
    Get-WURegistrySettingCandidate -Setting $setting -Scope Auto

    Selects a complete candidate set and returns its resolved scope.

    .INPUTS
    None

    .OUTPUTS
    System.Management.Automation.PSCustomObject
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [System.Collections.Hashtable]$Setting,

        [Parameter(Mandatory = $true)]
        [ValidateSet('Auto', 'User', 'Machine')]
        [string]$Scope
    )

    $scopesToTry = @($Scope)
    if ($Scope -eq 'Auto') {
        $scopesToTry = @('User', 'Machine')
    }

    foreach ($scopeToTry in $scopesToTry) {
        $propertySelections = @()
        foreach ($propertyName in @($Setting.Properties.Keys | Sort-Object)) {
            $matchedCandidate = $null
            foreach ($candidate in @($Setting.Properties[$propertyName])) {
                $candidateScope = $null
                if ($candidate.Path -match '^Registry::HKEY_CURRENT_USER\\') {
                    $candidateScope = 'User'
                } elseif ($candidate.Path -match '^Registry::HKEY_(LOCAL_MACHINE|CURRENT_CONFIG)\\') {
                    $candidateScope = 'Machine'
                }

                if ($candidateScope -eq $scopeToTry) {
                    $matchedCandidate = $candidate
                    break
                }
            }

            if ($null -eq $matchedCandidate) {
                $propertySelections = @()
                break
            }

            $propertySelections += [pscustomobject]@{
                Name = [string]$propertyName
                Candidate = $matchedCandidate
            }
        }

        if ($propertySelections.Count -eq $Setting.Properties.Count) {
            return [pscustomobject]@{
                Scope = $scopeToTry
                Properties = $propertySelections
            }
        }
    }

    throw "The registry setting does not support the requested scope: $Scope"
}
