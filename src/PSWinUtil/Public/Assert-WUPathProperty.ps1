function Assert-WUPathProperty {
    <#
    .SYNOPSIS
    Requires PowerShell paths to match selected properties.

    .DESCRIPTION
    Tests PowerShell paths with Test-WUPathProperty and reports an error when a path does not match the selected provider item type. AllowNonExisting permits a missing path while still validating an existing path. Successful checks produce no output.

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

        $testArguments = Select-WUBoundParameter -BoundParameters $PSBoundParameters -Name 'Leaf', 'Container'
    }

    process {
        $isLiteralPath = $PSBoundParameters.ContainsKey('LiteralPath')
        $paths = if ($isLiteralPath) {
            $LiteralPath
        } else {
            $Path
        }
        $pathParameterName = if ($isLiteralPath) { 'LiteralPath' } else { 'Path' }

        foreach ($inputPath in $paths) {
            if ($AllowNonExisting) {
                $existenceArguments = @{
                    ErrorAction = 'Stop'
                }
                $existenceArguments[$pathParameterName] = $inputPath
                if (-not (Test-Path @existenceArguments)) {
                    continue
                }
            }

            $testArguments[$pathParameterName] = $inputPath
            $results = @(Test-WUPathProperty @testArguments)
            if ($results -contains $false) {
                throw "The path does not match the required properties: $inputPath"
            }
        }
    }
}
