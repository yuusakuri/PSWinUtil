function Assert-WUPathProperty {
    <#
    .SYNOPSIS
    Requires PowerShell paths to match selected properties.

    .DESCRIPTION
    Expands wildcard Path values, uses Test-WUPathProperty, and reports an error when a path is missing or does not match the selected provider item type. LiteralPath values are checked without wildcard interpretation. AllowNonExisting permits a missing path while still validating an existing path. Successful checks produce no output.

    .PARAMETER Path
    Specifies one or more PowerShell paths to check. Wildcards are supported.

    .PARAMETER LiteralPath
    Specifies one or more PowerShell paths to check without wildcard interpretation.

    .PARAMETER Leaf
    Requires the path to identify a provider leaf item.

    .PARAMETER Container
    Requires the path to identify a provider container item.

    .PARAMETER AllowNonExisting
    Permits a missing path. An existing path must still match the selected provider item type.

    .EXAMPLE
    Assert-WUPathProperty -Path '.\settings.json' -Leaf

    Completes without output when settings.json is a leaf item.

    .EXAMPLE
    Assert-WUPathProperty -Path '.\certificates\*.pem' -Leaf

    Completes without output when every matching path is a leaf item.

    .EXAMPLE
    Assert-WUPathProperty -LiteralPath 'Env:\PATH' -Leaf

    Completes without output because PATH is a leaf item in the Environment provider.

    .EXAMPLE
    Assert-WUPathProperty -Path '.\missing'

    Reports an error because the path does not exist.

    .EXAMPLE
    Assert-WUPathProperty -Path '.\output' -Container -AllowNonExisting

    Completes without output when output is missing or is an existing container item.

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
        [switch]$AllowNonExisting
    )

    begin {
        if ($Leaf -and $Container) {
            throw 'Leaf and Container cannot be specified together.'
        }
    }

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
                    $resolveParameters = @{
                        ParameterSetName = $PSCmdlet.ParameterSetName
                        Path = $selectedPath
                        ErrorAction = 'Stop'
                    }
                    $pathsToTest = @(
                        Resolve-WUPathFromParameter @resolveParameters
                    )
                } catch [System.Management.Automation.ItemNotFoundException] {
                    if ($AllowNonExisting) {
                        continue
                    }
                    throw
                }
            }

            if ($pathsToTest.Count -eq 0) {
                if ($AllowNonExisting) {
                    continue
                }
                throw [System.Management.Automation.ItemNotFoundException]::new()
            }

            foreach ($pathToTest in $pathsToTest) {
                $literalPathToTest = $pathToTest
                if ($pathToTest -is [System.Management.Automation.PathInfo]) {
                    $literalPathToTest = $pathToTest.Path
                }

                if (
                    $AllowNonExisting -and
                    -not (Test-Path -LiteralPath $literalPathToTest -ErrorAction Stop)
                ) {
                    continue
                }

                $testParameters = Select-WUBoundParameter `
                    -BoundParameters $PSBoundParameters `
                    -Name 'Leaf', 'Container'
                $testParameters['LiteralPath'] = $literalPathToTest
                if (-not (Test-WUPathProperty @testParameters)) {
                    throw "The path does not match the required properties: $literalPathToTest"
                }
            }
        }
    }
}
