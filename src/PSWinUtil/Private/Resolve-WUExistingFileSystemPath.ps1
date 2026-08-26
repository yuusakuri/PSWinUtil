function Resolve-WUExistingFileSystemPath {
    <#
    .SYNOPSIS
    Resolves existing file system paths.

    .DESCRIPTION
    Resolves wildcard Path values or exact LiteralPath values, rejects non-file-system providers, validates the selected path properties, and returns fully qualified provider paths.

    .PARAMETER Path
    Specifies one or more paths. Wildcards are supported.

    .PARAMETER LiteralPath
    Specifies one or more paths without wildcard interpretation.

    .PARAMETER Leaf
    Requires each resolved path to be a file.

    .PARAMETER Container
    Requires each resolved path to be a directory.

    .PARAMETER Readable
    Requires each resolved path to be readable by the current process.

    .PARAMETER Writable
    Requires each resolved path to be writable by the current process.

    .EXAMPLE
    Resolve-WUExistingFileSystemPath -Path '.\*.psd1' -Leaf -Readable

    Returns fully qualified paths for readable PowerShell data files in the current directory.

    .INPUTS
    System.String

    .OUTPUTS
    System.String
    #>
    [CmdletBinding(DefaultParameterSetName = 'Path')]
    [OutputType([string])]
    param(
        [Parameter(
            Mandatory = $true,
            ParameterSetName = 'Path',
            Position = 0,
            ValueFromPipeline = $true,
            ValueFromPipelineByPropertyName = $true
        )]
        [ValidateNotNullOrEmpty()]
        [SupportsWildcards()]
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
        [switch]$Leaf,

        [Parameter()]
        [switch]$Container,

        [Parameter()]
        [switch]$Readable,

        [Parameter()]
        [switch]$Writable
    )

    process {
        $selectedPaths = $Path
        $resolveParameterName = 'Path'
        if ($PSCmdlet.ParameterSetName -eq 'LiteralPath') {
            $selectedPaths = $LiteralPath
            $resolveParameterName = 'LiteralPath'
        }

        foreach ($selectedPath in $selectedPaths) {
            $resolveParameters = @{
                $resolveParameterName = $selectedPath
                ErrorAction = 'Stop'
            }
            foreach ($resolvedPath in @(Resolve-Path @resolveParameters)) {
                if ($resolvedPath.Provider.Name -ne 'FileSystem') {
                    throw "The path must use the FileSystem provider: $($resolvedPath.Path)"
                }

                $assertParameters = @{
                    Path = $resolvedPath.ProviderPath
                }
                foreach ($propertyName in @('Leaf', 'Container', 'Readable', 'Writable')) {
                    if ($PSBoundParameters.ContainsKey($propertyName) -and $PSBoundParameters[$propertyName]) {
                        $assertParameters[$propertyName] = $true
                    }
                }
                Assert-WUPathProperty @assertParameters
                $resolvedPath.ProviderPath
            }
        }
    }
}
