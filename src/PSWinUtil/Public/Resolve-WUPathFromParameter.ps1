function Resolve-WUPathFromParameter {
    <#
    .SYNOPSIS
    Resolves paths selected by a parameter set.

    .DESCRIPTION
    Selects Path or LiteralPath from a parameter set name and resolves the selected values with Resolve-WUPath. Custom parameter set names can be supplied for commands whose sets are not named Path and LiteralPath.

    .PARAMETER ParameterSetName
    Specifies the active parameter set name.

    .PARAMETER Path
    Specifies one or more paths to resolve when the active set matches PathSetName. Wildcards are supported.

    .PARAMETER LiteralPath
    Specifies one or more paths to resolve without wildcard interpretation when the active set matches LiteralPathSetName.

    .PARAMETER PathSetName
    Specifies the parameter set name that selects Path. The default value is Path.

    .PARAMETER LiteralPathSetName
    Specifies the parameter set name that selects LiteralPath. The default value is LiteralPath.

    .PARAMETER Relative
    Returns each resolved path relative to the current location.

    .PARAMETER DenyMultiplePaths
    Requires the selected values to resolve to exactly one path.

    .EXAMPLE
    Resolve-WUPathFromParameter `
        -ParameterSetName 'Path' `
        -Path '.\scripts\*.ps1'

    Resolves the scripts selected by Path.

    .EXAMPLE
    Resolve-WUPathFromParameter `
        -ParameterSetName 'SourceLiteralPath' `
        -LiteralPath '.\source[1].ps1' `
        -PathSetName 'SourcePath' `
        -LiteralPathSetName 'SourceLiteralPath' `
        -DenyMultiplePaths

    Resolves exactly one literal path by using custom parameter set names.

    .INPUTS
    None

    .OUTPUTS
    System.Management.Automation.PathInfo
    System.String
    #>
    [CmdletBinding()]
    [OutputType([System.Management.Automation.PathInfo], [string])]
    param(
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$ParameterSetName,

        [Parameter()]
        [SupportsWildcards()]
        [string[]]$Path,

        [Parameter()]
        [Alias('PSPath', 'LP')]
        [string[]]$LiteralPath,

        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [string]$PathSetName = 'Path',

        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [string]$LiteralPathSetName = 'LiteralPath',

        [Parameter()]
        [switch]$Relative,

        [Parameter()]
        [switch]$DenyMultiplePaths
    )

    $resolveParameters = Select-WUBoundParameter `
        -BoundParameters $PSBoundParameters `
        -Name 'Relative', 'DenyMultiplePaths'
    if ($ParameterSetName -eq $PathSetName) {
        $resolveParameters.Path = $Path
    } elseif ($ParameterSetName -eq $LiteralPathSetName) {
        $resolveParameters.LiteralPath = $LiteralPath
    } else {
        throw "Parameter set '$ParameterSetName' is not supported."
    }

    return @(Resolve-WUPath @resolveParameters)
}
