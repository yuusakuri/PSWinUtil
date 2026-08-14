function Compare-WUPath {
    <#
    .SYNOPSIS
    Compares two PATH environment variable items.

    .DESCRIPTION
    Compares two paths without case sensitivity after trimming surrounding spaces and a trailing backslash. Drive roots keep their trailing backslash.

    .PARAMETER ReferencePath
    Specifies the first path to compare.

    .PARAMETER DifferencePath
    Specifies the second path to compare.

    .EXAMPLE
    Compare-WUPath -ReferencePath 'C:\Tools' -DifferencePath 'c:\tools\'

    Returns true because the paths have the same normalized value.

    .INPUTS
    None

    .OUTPUTS
    System.Boolean
    #>
    [CmdletBinding()]
    [OutputType([bool])]
    param(
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$ReferencePath,

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$DifferencePath
    )

    $normalizedReferencePath = $ReferencePath.Trim()
    $normalizedDifferencePath = $DifferencePath.Trim()

    if ($normalizedReferencePath.Length -gt 3) {
        $normalizedReferencePath = $normalizedReferencePath.TrimEnd([char]'\')
    }
    if ($normalizedDifferencePath.Length -gt 3) {
        $normalizedDifferencePath = $normalizedDifferencePath.TrimEnd([char]'\')
    }

    [string]::Equals(
        $normalizedReferencePath,
        $normalizedDifferencePath,
        [System.StringComparison]::OrdinalIgnoreCase
    )
}
