function Test-WURegistryConfigOption {
    [CmdletBinding()]
    [OutputType([bool])]
    param(
        [Parameter(Mandatory = $true)]
        [AllowNull()]
        [object]$Option,

        [Parameter(Mandatory = $true)]
        [AllowEmptyCollection()]
        [string[]]$ExistingName,

        [Parameter(Mandatory = $true)]
        [type[]]$ValueType
    )

    if (
        $Option -isnot [System.Collections.Hashtable] -or
        -not $Option.ContainsKey('Name') -or
        -not $Option.ContainsKey('Action') -or
        $Option.Name -isnot [string] -or
        [string]::IsNullOrWhiteSpace($Option.Name) -or
        $Option.Name -in $ExistingName -or
        $Option.Action -notin @('Set', 'Remove')
    ) {
        return $false
    }

    if ($Option.Action -eq 'Remove') {
        return $Option.Count -eq 2
    }

    if ($Option.Count -ne 3 -or -not $Option.ContainsKey('Value') -or $null -eq $Option.Value) {
        return $false
    }

    foreach ($type in $ValueType) {
        if ($type.IsInstanceOfType($Option.Value)) {
            return $true
        }
    }

    $false
}
