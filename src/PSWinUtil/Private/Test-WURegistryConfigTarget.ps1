function Test-WURegistryConfigTarget {
    [CmdletBinding()]
    [OutputType([bool])]
    param(
        [Parameter(Mandatory = $true)]
        [AllowNull()]
        [object]$Target,

        [Parameter(Mandatory = $true)]
        [AllowEmptyCollection()]
        [string[]]$ExistingScope,

        [Parameter(Mandatory = $true)]
        [hashtable]$ValueTypes
    )

    if (
        $Target -isnot [System.Collections.Hashtable] -or
        $Target.Count -ne 2 -or
        -not $Target.ContainsKey('Scope') -or
        -not $Target.ContainsKey('Properties') -or
        $Target.Scope -notin @('User', 'Machine') -or
        $Target.Scope -in $ExistingScope
    ) {
        return $false
    }

    $properties = @($Target.Properties)
    if ($properties.Count -eq 0) {
        return $false
    }

    $pathPattern = if ($Target.Scope -eq 'User') {
        '^Registry::HKEY_CURRENT_USER\\.+'
    } else {
        '^Registry::HKEY_(LOCAL_MACHINE|CURRENT_CONFIG)\\.+'
    }
    $propertyNames = @()
    $targetOptionNames = $null

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
            return $false
        }
        $propertyNames += $property.Name

        $options = @($property.Options)
        if ($options.Count -eq 0) {
            return $false
        }

        $optionNames = @()
        foreach ($option in $options) {
            if (-not (Test-WURegistryConfigOption -Option $option -ExistingName $optionNames -ValueType $ValueTypes[$property.Type])) {
                return $false
            }
            $optionNames += $option.Name
        }

        $optionNames = @($optionNames | Sort-Object)
        if ($null -ne $targetOptionNames -and
            @(Compare-Object -ReferenceObject $targetOptionNames -DifferenceObject $optionNames).Count -gt 0) {
            return $false
        }
        $targetOptionNames = $optionNames
    }

    $true
}
