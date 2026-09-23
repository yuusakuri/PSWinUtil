function Test-WURegistryConfiguration {
    [CmdletBinding()]
    [OutputType([pscustomobject])]
    param(
        [Parameter(Mandatory = $true)]
        [AllowNull()]
        [object]$Configuration,

        [Parameter(Mandatory = $true)]
        [AllowEmptyCollection()]
        [string[]]$ExistingScope,

        [Parameter(Mandatory = $true)]
        [hashtable]$ValueTypes
    )

    if (
        $Configuration -isnot [System.Collections.Hashtable] -or
        $Configuration.Count -ne 2 -or
        -not $Configuration.ContainsKey('Scope') -or
        -not $Configuration.ContainsKey('Properties') -or
        $Configuration.Scope -notin @('User', 'Machine') -or
        $Configuration.Scope -in $ExistingScope
    ) {
        return
    }

    $properties = @($Configuration.Properties)
    if ($properties.Count -eq 0) {
        return
    }

    $pathPattern = if ($Configuration.Scope -eq 'User') {
        '^Registry::HKEY_CURRENT_USER\\.+'
    } else {
        '^Registry::HKEY_(LOCAL_MACHINE|CURRENT_CONFIG)\\.+'
    }
    $propertyNames = @()
    $configurationOptionNames = $null

    foreach ($property in $properties) {
        if (
            $property -isnot [System.Collections.Hashtable] -or
            $property.Count -ne 4 -or
            -not $property.ContainsKey('Name') -or
            -not $property.ContainsKey('Path') -or
            -not $property.ContainsKey('Type') -or
            -not $property.ContainsKey('Options') -or
            $property.Name -isnot [string] -or
            [string]::IsNullOrWhiteSpace($property.Name) -or
            $property.Name -in $propertyNames -or
            $property.Path -isnot [string] -or
            [string]::IsNullOrWhiteSpace($property.Path) -or
            $property.Type -notin $ValueTypes.Keys -or
            $property.Path -notmatch $pathPattern
        ) {
            return
        }
        $propertyNames += $property.Name

        $options = @($property.Options)
        if ($options.Count -eq 0) {
            return
        }

        $optionNames = @()
        foreach ($option in $options) {
            if (-not (Test-WURegistryOption -Option $option -ExistingName $optionNames -ValueType $ValueTypes[$property.Type])) {
                return
            }
            $optionNames += $option.Name
        }

        $optionNames = @($optionNames | Sort-Object)
        if ($null -ne $configurationOptionNames -and
            @(Compare-Object -ReferenceObject $configurationOptionNames -DifferenceObject $optionNames).Count -gt 0) {
            return
        }
        $configurationOptionNames = $optionNames
    }

    [pscustomobject]@{
        Scope = $Configuration.Scope
        OptionNames = $configurationOptionNames
    }
}
