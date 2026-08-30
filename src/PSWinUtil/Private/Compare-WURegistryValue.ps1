function Compare-WURegistryValue {
    <#
    .SYNOPSIS
    Compares registry values.

    .DESCRIPTION
    Compares scalar and array registry values without converting their contents to display text.

    .PARAMETER ReferenceValue
    Specifies the expected registry value.

    .PARAMETER DifferenceValue
    Specifies the registry value to compare.

    .EXAMPLE
    Compare-WURegistryValue -ReferenceValue 1 -DifferenceValue 1

    Returns true because both registry values are equal.

    .INPUTS
    None

    .OUTPUTS
    System.Boolean
    #>
    [CmdletBinding()]
    [OutputType([bool])]
    param(
        [Parameter(Mandatory = $true)]
        [AllowNull()]
        [object]$ReferenceValue,

        [Parameter(Mandatory = $true)]
        [AllowNull()]
        [object]$DifferenceValue
    )

    if ($null -eq $ReferenceValue -or $null -eq $DifferenceValue) {
        return $null -eq $ReferenceValue -and $null -eq $DifferenceValue
    }

    $referenceIsArray = $ReferenceValue -is [System.Array]
    $differenceIsArray = $DifferenceValue -is [System.Array]
    if ($referenceIsArray -ne $differenceIsArray) {
        return $false
    }

    if (-not $referenceIsArray) {
        return $ReferenceValue -ceq $DifferenceValue
    }

    if ($ReferenceValue.Count -ne $DifferenceValue.Count) {
        return $false
    }

    for ($index = 0; $index -lt $ReferenceValue.Count; $index++) {
        if (-not (Compare-WURegistryValue -ReferenceValue $ReferenceValue[$index] -DifferenceValue $DifferenceValue[$index])) {
            return $false
        }
    }

    $true
}
