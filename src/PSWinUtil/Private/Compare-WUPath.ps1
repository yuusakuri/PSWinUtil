function Compare-WUPath {
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
