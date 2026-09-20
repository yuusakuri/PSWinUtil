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
        [string]$Scope = 'Process'
    )

    $scopeName = $Scope
    $normalize = {
        param([string]$Value)

        $expandedValue = [PSWinUtil.EnvironmentVariableExpander]::Expand($Value.Trim(), $scopeName)
        $expandedValue = $expandedValue.Replace('/', '\')
        $isFullyQualified = $expandedValue -match '^(?:[A-Za-z]:[\\/]|\\\\)'
        $rootLength = 0
        if ($isFullyQualified) {
            try {
                $expandedValue = [System.IO.Path]::GetFullPath($expandedValue)
                $rootLength = [System.IO.Path]::GetPathRoot($expandedValue).Length
            } catch {
                return $expandedValue.TrimEnd([char]'\')
            }
        }
        if ($expandedValue.Length -gt $rootLength) {
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
