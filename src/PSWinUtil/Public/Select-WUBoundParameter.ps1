function Select-WUBoundParameter {
    <#
    .SYNOPSIS
    Selects named entries from a bound parameter dictionary.

    .DESCRIPTION
    Creates a hashtable containing only the requested names that exist in the supplied dictionary. Values are preserved even when they are false or null.

    .PARAMETER BoundParameters
    Specifies the bound parameter dictionary from which entries are selected.

    .PARAMETER Name
    Specifies the parameter names to select.

    .EXAMPLE
    $parameters = Select-WUBoundParameter -BoundParameters $PSBoundParameters -Name 'WhatIf', 'Confirm'

    Creates a hashtable containing the bound WhatIf and Confirm parameters.

    .INPUTS
    None

    .OUTPUTS
    System.Collections.Hashtable
    #>
    [CmdletBinding()]
    [OutputType([hashtable])]
    param(
        [Parameter(Mandatory = $true)]
        [System.Collections.IDictionary]$BoundParameters,

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string[]]$Name
    )

    $selectedParameters = @{}
    $containsKeyMethod = $BoundParameters.PSObject.Methods['ContainsKey']

    foreach ($parameterName in $Name) {
        $containsParameter = if ($null -ne $containsKeyMethod) {
            $BoundParameters.ContainsKey($parameterName)
        } else {
            $BoundParameters.Contains($parameterName)
        }
        if ($containsParameter) {
            $selectedParameters[$parameterName] = $BoundParameters[$parameterName]
        }
    }

    return $selectedParameters
}
