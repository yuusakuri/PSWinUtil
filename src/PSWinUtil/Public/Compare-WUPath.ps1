function Compare-WUPath {
    <#
    .SYNOPSIS
    Compares two PATH environment variable items.

    .DESCRIPTION
    Compares two PATH entries after expanding environment variables and normalizing Windows path syntax. The stored text is not changed.

    .PARAMETER ReferencePath
    Specifies the first path to compare.

    .PARAMETER DifferencePath
    Specifies the second path to compare.

    .PARAMETER Scope
    Specifies the environment-variable scope used to resolve references in the paths.

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
        [string]$DifferencePath,

        [Parameter()]
        [ValidateSet('Process', 'User', 'Machine')]
        [ValidateCount(1, 1)]
        [string[]]$Scope = 'Process'
    )

    $normalize = {
        param([string]$Value)

        $expandedValue = [PSWinUtil.EnvironmentVariableExpander]::Expand($Value.Trim(), $Scope[0])
        $expandedValue = $expandedValue.Replace('/', '\')
        $isFullyQualified = $expandedValue -match '^(?:[A-Za-z]:[\\/]|\\\\)'
        if ($isFullyQualified) {
            $expandedValue = [System.IO.Path]::GetFullPath($expandedValue)
        }
        if ($expandedValue.Length -gt 3) {
            $expandedValue = $expandedValue.TrimEnd([char]'\')
        }

        $expandedValue
    }

    $normalizedReferencePath = & $normalize $ReferencePath
    $normalizedDifferencePath = & $normalize $DifferencePath

    [string]::Equals(
        $normalizedReferencePath,
        $normalizedDifferencePath,
        [System.StringComparison]::OrdinalIgnoreCase
    )
}
