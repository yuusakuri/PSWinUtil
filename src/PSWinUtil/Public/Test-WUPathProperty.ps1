function Test-WUPathProperty {
    <#
    .SYNOPSIS
    Tests PowerShell path properties.

    .DESCRIPTION
    Expands wildcard Path values and returns a Boolean value for each resolved path. LiteralPath values are tested without wildcard interpretation. A missing path or an unmatched pattern returns false. An existing path can also be tested for its provider item type.

    .PARAMETER Path
    Specifies one or more PowerShell paths to test. Wildcards are supported.

    .PARAMETER LiteralPath
    Specifies one or more PowerShell paths to test without wildcard interpretation.

    .PARAMETER Leaf
    Tests whether the path identifies a provider leaf item.

    .PARAMETER Container
    Tests whether the path identifies a provider container item.

    .EXAMPLE
    Test-WUPathProperty -Path '.\settings.json' -Leaf

    Returns true when settings.json exists as a leaf item.

    .EXAMPLE
    Test-WUPathProperty -Path '.\certificates\*.pem' -Leaf

    Returns one Boolean value for each matching leaf item.

    .EXAMPLE
    Test-WUPathProperty -LiteralPath 'Env:\PATH' -Leaf

    Returns true because PATH is a leaf item in the Environment provider.

    .EXAMPLE
    Test-WUPathProperty -Path '.\missing'

    Returns false when the path does not exist.

    .INPUTS
    System.String

    .OUTPUTS
    System.Boolean
    #>
    [CmdletBinding(DefaultParameterSetName = 'Path')]
    [OutputType([bool])]
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
        [switch]$Container
    )

    begin {
        if ($Leaf -and $Container) {
            throw 'Leaf and Container cannot be specified together.'
        }
    }

    process {
        $usesLiteralPath = $PSBoundParameters.ContainsKey('LiteralPath')
        $selectedPaths = $Path
        if ($usesLiteralPath) {
            $selectedPaths = $LiteralPath
        }

        foreach ($selectedPath in $selectedPaths) {
            $pathsToTest = @($selectedPath)
            if (
                -not $usesLiteralPath -and
                [System.Management.Automation.WildcardPattern]::ContainsWildcardCharacters($selectedPath)
            ) {
                try {
                    $pathsToTest = @(Resolve-WUPath -Path $selectedPath -ErrorAction Stop)
                } catch [System.Management.Automation.ItemNotFoundException] {
                    $false
                    continue
                }
            }

            if ($pathsToTest.Count -eq 0) {
                $false
                continue
            }

            foreach ($pathToTest in $pathsToTest) {
                $literalPathToTest = $pathToTest
                if ($pathToTest -is [System.Management.Automation.PathInfo]) {
                    $literalPathToTest = $pathToTest.Path
                }

                $pathType = 'Any'
                if ($Leaf) {
                    $pathType = 'Leaf'
                } elseif ($Container) {
                    $pathType = 'Container'
                }

                try {
                    Test-Path `
                        -LiteralPath $literalPathToTest `
                        -PathType $pathType `
                        -ErrorAction Stop
                } catch {
                    $false
                }
            }
        }
    }
}
