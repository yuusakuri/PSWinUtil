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
    Specifies the environment-variable scope used to resolve references in the paths. User includes Machine as a fallback; Machine and Process use only their named scope.

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
        [string[]]$Scope = 'Process'
    )

    if ($Scope.Count -ne 1) {
        throw 'Compare-WUPath accepts exactly one scope.'
    }

    $scopes = switch ($Scope[0]) {
        'Process' { @('Process') }
        'User' { @('User', 'Machine') }
        'Machine' { @('Machine') }
    }

    $normalize = {
        param([string]$Value)

        $expandedValue = [System.Text.RegularExpressions.Regex]::Replace(
            $Value.Trim(),
            '%([^%]+)%',
            {
                param($Match)

                foreach ($lookupScope in $scopes) {
                    $lookupValues = @(Get-WUEnvironmentVariable -Name $Match.Groups[1].Value -Scope $lookupScope)
                    if ($lookupValues.Count -gt 0) {
                        return [string]$lookupValues[0]
                    }
                }

                $Match.Value
            }
        )
        $expandedValue = $expandedValue.Replace('/', '\')
        if ($expandedValue -notmatch '%[^%]+%') {
            try {
                $expandedValue = [System.IO.Path]::GetFullPath($expandedValue)
            } catch {
                $expandedValue = $expandedValue.TrimEnd([char]'\')
            }
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
