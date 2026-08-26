function Assert-WUPathProperty {
    <#
    .SYNOPSIS
    Requires file system paths to match selected properties.

    .DESCRIPTION
    Expands wildcard Path values, uses Test-WUPathProperty, and reports an error when a path is missing or does not match every selected property. LiteralPath values are checked without wildcard interpretation. AllowNonExisting permits a missing path while still validating an existing path. Successful checks produce no output.

    .PARAMETER Path
    Specifies one or more file system paths to check. Wildcards are supported.

    .PARAMETER LiteralPath
    Specifies one or more file system paths to check without wildcard interpretation.

    .PARAMETER Leaf
    Requires the path to be a file.

    .PARAMETER Container
    Requires the path to be a directory.

    .PARAMETER Readable
    Requires the path to be readable by the current process.

    .PARAMETER Writable
    Requires the path to be writable by the current process.

    .PARAMETER AllowNonExisting
    Permits a missing path. An existing path must still match every selected property.

    .EXAMPLE
    Assert-WUPathProperty -Path '.\settings.json' -Leaf -Readable

    Completes without output when settings.json is a readable file.

    .EXAMPLE
    Assert-WUPathProperty -Path '.\certificates\*.pem' -Leaf -Readable

    Completes without output when every matching PEM file is readable.

    .EXAMPLE
    Assert-WUPathProperty -Path '.\missing'

    Reports an error because the path does not exist.

    .EXAMPLE
    Assert-WUPathProperty -Path '.\output' -Container -AllowNonExisting

    Completes without output when output is missing or is an existing directory.

    .INPUTS
    System.String

    .OUTPUTS
    None
    #>
    [CmdletBinding(DefaultParameterSetName = 'Path')]
    param(
        [Parameter(
            Mandatory = $true,
            ParameterSetName = 'Path',
            Position = 0,
            ValueFromPipeline = $true,
            ValueFromPipelineByPropertyName = $true
        )]
        [Alias('FullName')]
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
        [switch]$Writable,

        [Parameter()]
        [switch]$AllowNonExisting
    )

    process {
        $selectedPaths = $Path
        if ($PSCmdlet.ParameterSetName -eq 'LiteralPath') {
            $selectedPaths = $LiteralPath
        }

        foreach ($selectedPath in $selectedPaths) {
            $pathsToTest = @($selectedPath)
            if (
                $PSCmdlet.ParameterSetName -eq 'Path' -and
                [System.Management.Automation.WildcardPattern]::ContainsWildcardCharacters($selectedPath)
            ) {
                try {
                    $pathsToTest = @(Resolve-Path -Path $selectedPath -ErrorAction Stop)
                } catch [System.Management.Automation.ItemNotFoundException] {
                    if (-not $AllowNonExisting) {
                        throw
                    }
                }
            }

            foreach ($pathToTest in $pathsToTest) {
                if ($pathToTest -is [System.Management.Automation.PathInfo]) {
                    if ($pathToTest.Provider.Name -ne 'FileSystem') {
                        throw "The path must use the FileSystem provider: $($pathToTest.Path)"
                    }
                    $fullPath = $pathToTest.ProviderPath
                } else {
                    $fullPath = ConvertTo-WUFullPath -Path $pathToTest
                }

                if (
                    $AllowNonExisting -and
                    -not (Test-Path -LiteralPath $fullPath -ErrorAction Stop)
                ) {
                    continue
                }

                $testParameters = Select-WUBoundParameter `
                    -BoundParameters $PSBoundParameters `
                    -Name 'Leaf', 'Container', 'Readable', 'Writable'
                $testParameters['LiteralPath'] = $fullPath

                if (-not (Test-WUPathProperty @testParameters)) {
                    throw "The path does not match the required properties: $pathToTest"
                }
            }
        }
    }
}
