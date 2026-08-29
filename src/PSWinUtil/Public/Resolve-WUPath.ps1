function Resolve-WUPath {
    <#
    .SYNOPSIS
    Resolves PowerShell paths with optional single-result enforcement.

    .DESCRIPTION
    Wraps Resolve-Path and preserves its wildcard, literal path, pipeline, relative path, and credential behavior. DenyMultiplePaths requires the complete invocation to resolve to exactly one result.

    .PARAMETER Path
    Specifies one or more paths to resolve. Wildcards are supported.

    .PARAMETER LiteralPath
    Specifies one or more paths to resolve without wildcard interpretation.

    .PARAMETER Relative
    Returns each resolved path relative to the current location.

    .PARAMETER Credential
    Specifies credentials that a provider supports when resolving paths.

    .PARAMETER DenyMultiplePaths
    Requires the complete invocation to resolve to exactly one path. No result raises ItemNotFoundException, and more than one result raises ArgumentException.

    .EXAMPLE
    Resolve-WUPath -Path '.\certificates\*.pem'

    Returns every matching certificate path.

    .EXAMPLE
    Resolve-WUPath -Path '.\certificates\*.pem' -DenyMultiplePaths

    Returns the matching certificate path when exactly one file matches and reports an error otherwise.

    .INPUTS
    System.String

    .OUTPUTS
    System.Management.Automation.PathInfo
    System.String
    #>
    [CmdletBinding(DefaultParameterSetName = 'Path')]
    [OutputType([System.Management.Automation.PathInfo], [string])]
    param(
        [Parameter(
            Mandatory = $true,
            ParameterSetName = 'Path',
            Position = 0,
            ValueFromPipeline = $true,
            ValueFromPipelineByPropertyName = $true
        )]
        [SupportsWildcards()]
        [ValidateNotNullOrEmpty()]
        [string[]]$Path,

        [Parameter(
            Mandatory = $true,
            ParameterSetName = 'LiteralPath',
            ValueFromPipelineByPropertyName = $true
        )]
        [Alias('PSPath', 'LP')]
        [ValidateNotNullOrEmpty()]
        [string[]]$LiteralPath,

        [Parameter()]
        [switch]$Relative,

        [Parameter()]
        [System.Management.Automation.Credential()]
        [System.Management.Automation.PSCredential]$Credential,

        [Parameter()]
        [switch]$DenyMultiplePaths
    )

    begin {
        $pathsToResolve = [System.Collections.Generic.List[string]]::new()
    }

    process {
        $isLiteralPath = $PSBoundParameters.ContainsKey('LiteralPath')
        $pathParameterName = 'Path'
        $paths = $Path
        if ($isLiteralPath) {
            $pathParameterName = 'LiteralPath'
            $paths = $LiteralPath
        }

        if ($DenyMultiplePaths) {
            foreach ($inputPath in $paths) {
                $pathsToResolve.Add($inputPath)
            }
        } else {
            $resolveParameters = Select-WUBoundParameter `
                -BoundParameters $PSBoundParameters `
                -Name 'Relative', 'Credential'
            $resolveParameters[$pathParameterName] = $paths
            Resolve-Path @resolveParameters
        }
    }

    end {
        if (-not $DenyMultiplePaths) {
            return
        }

        $resolveParameters = Select-WUBoundParameter `
            -BoundParameters $PSBoundParameters `
            -Name 'Relative', 'Credential'
        $resolveParameters[$pathParameterName] = $pathsToResolve.ToArray()
        $resolveParameters['ErrorAction'] = 'Stop'
        $resolvedPaths = @(Resolve-Path @resolveParameters)

        if ($resolvedPaths.Count -eq 1) {
            $resolvedPaths[0]
        } elseif ($resolvedPaths.Count -gt 1) {
            throw [System.ArgumentException]::new(
                'Path resolved to more than one result'
            )
        } else {
            throw [System.Management.Automation.ItemNotFoundException]::new()
        }
    }
}
