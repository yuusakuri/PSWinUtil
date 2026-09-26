function Get-WURegistrySetting {
    <#
    .SYNOPSIS
    Gets a Windows registry setting state.

    .DESCRIPTION
    Gets the state of a named registry setting in one or more scopes. Auto selects the User target before the Machine target. The result is an option name, NotConfigured, or Mixed.

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
        $configs = @((Import-WURegistryConfig).Configs)
    }

    process {
        foreach ($inputName in $Name) {
            $registryConfig = (@($configs | Where-Object { $_.Name -ieq $inputName }) | Select-Object -First 1)
            if ($null -eq $registryConfig) {
                throw "The registry setting was not found: $inputName"
            }

            foreach ($targetScope in $scopes) {
                $target = Get-WURegistryConfigTarget -Config $registryConfig -Scope $targetScope
                $propertyStates = @(
                    foreach ($property in $target.Properties) {
                        $registryProperty = Get-WURegistryProperty -Path $property.Path -Name $property.Name
                        [pscustomobject]@{
                            Property = $property
                            RegistryProperty = $registryProperty
                        }
                    }
                )

                $state = (@(
                        ($target.Properties | Select-Object -First 1).Options.Name |
                            Sort-Object |
                            Where-Object { Test-WURegistryConfigOptionApplied -PropertyState $propertyStates -OptionName $_ } |
                            Select-Object -First 1
                        ) | Select-Object -First 1)

                    $configuredPropertyCount = @(
                        $propertyStates | Where-Object { $null -ne $_.RegistryProperty }
                    ).Count
                    if ($null -eq $state -and $configuredPropertyCount -eq 0) {
                        $state = 'NotConfigured'
                    }
                    if ($null -eq $state) {
                        $state = 'Mixed'
                    }

                    [pscustomobject]@{
                        PSTypeName = 'PSWinUtil.RegistryConfig'
                        Name = $inputName
                        Scope = $target.Scope
                        State = $state
                    }
                }
            }
        }
    }
