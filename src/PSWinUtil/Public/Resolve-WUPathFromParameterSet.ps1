function Resolve-WUPathFromParameterSet {
    <#
    .SYNOPSIS
    Resolves paths selected by a parameter set.

    .DESCRIPTION
    Selects Path or LiteralPath from an active parameter set name and resolves the selected values with Resolve-WUPath. Multiple custom parameter set names can select each path parameter.

    .PARAMETER ParameterSetName
    Specifies the active parameter set name.

    .PARAMETER Path
    Specifies one or more paths to resolve when the active set matches PathSetName. Wildcards are supported.

    .PARAMETER LiteralPath
    Specifies one or more paths to resolve without wildcard interpretation when the active set matches LiteralPathSetName.

    .PARAMETER PathSetName
    Specifies one or more parameter set names that select Path. The default value is Path.

    .PARAMETER LiteralPathSetName
    Specifies one or more parameter set names that select LiteralPath. The default value is LiteralPath.

    .PARAMETER Relative
    Returns each resolved path relative to the current location.

    .PARAMETER Credential
    Specifies credentials that a provider supports when resolving paths.

    .PARAMETER DenyMultiplePaths
    Requires the selected values to resolve to exactly one path.

    .EXAMPLE
    Resolve-WUPathFromParameterSet -ParameterSetName 'Path' -Path '.\scripts\*.ps1'

    Resolves the scripts selected by Path.

    .EXAMPLE
    $parameters = @{
        ParameterSetName = 'DestinationLiteralPath'
        LiteralPath = '.\output[1].txt'
        PathSetName = 'SourcePath', 'DestinationPath'
        LiteralPathSetName = 'SourceLiteralPath', 'DestinationLiteralPath'
        DenyMultiplePaths = $true
    }
    Resolve-WUPathFromParameterSet @parameters

    Resolves exactly one literal path by using multiple custom parameter set names.

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
        [string[]]$PathSetName = 'Path',

        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [string[]]$LiteralPathSetName = 'LiteralPath',

        [Parameter()]
        [switch]$Relative,

        [Parameter()]
        [System.Management.Automation.Credential()]
        [System.Management.Automation.PSCredential]$Credential,

        [Parameter()]
        [switch]$DenyMultiplePaths
    )

    $isPath = $PathSetName -contains $ParameterSetName
    $isLiteralPath = $LiteralPathSetName -contains $ParameterSetName
    if ($isPath -and $isLiteralPath) {
        throw "Parameter set '$ParameterSetName' cannot select both Path and LiteralPath."
    }
    if (-not $isPath -and -not $isLiteralPath) {
        throw "Parameter set '$ParameterSetName' is not supported."
    }

    $pathParameterName = 'Path'
    $paths = $Path
    if ($isLiteralPath) {
        $pathParameterName = 'LiteralPath'
        $paths = $LiteralPath
    }
    $invalidPaths = @($paths | Where-Object { [string]::IsNullOrEmpty($_) })
    if (@($paths).Count -eq 0 -or $invalidPaths.Count -gt 0) {
        throw "Parameter set '$ParameterSetName' does not contain a valid $pathParameterName value."
    }

    $resolveParameters = Select-WUBoundParameter -BoundParameters $PSBoundParameters -Name 'Relative', 'Credential', 'DenyMultiplePaths'
    $resolveParameters[$pathParameterName] = $paths
    Resolve-WUPath @resolveParameters
}
