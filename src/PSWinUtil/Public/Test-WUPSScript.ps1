function Test-WUPSScript {
    <#
    .SYNOPSIS
    Tests PowerShell script syntax.

    .DESCRIPTION
    Uses the parser from the current PowerShell process to test a file or script text. Path permits wildcards, while LiteralPath uses an exact path. The default result is Boolean. Detailed results include the parser errors and their source locations.

    .PARAMETER Path
    Specifies one or more PowerShell script files to parse. Wildcards are supported.

    .PARAMETER LiteralPath
    Specifies one or more PowerShell script files to parse without wildcard interpretation.

    .PARAMETER Script
    Specifies PowerShell script text to parse.

    .PARAMETER Detailed
    Returns an object containing IsValid, Input, and Errors instead of a Boolean value.

    .EXAMPLE
    Test-WUPSScript -Script 'Get-Item -Path .'

    Returns true because the script text has valid syntax.

    .EXAMPLE
    Test-WUPSScript -Script 'if (' -Detailed

    Returns a detailed result containing parser errors.

    .EXAMPLE
    Test-WUPSScript -LiteralPath '.\build[local].ps1'

    Tests the exact script file without interpreting brackets as a wildcard pattern.

    .INPUTS
    System.String

    .OUTPUTS
    System.Boolean
    System.Management.Automation.PSCustomObject
    #>
    [CmdletBinding(DefaultParameterSetName = 'Script')]
    param(
        [Parameter(
            Mandatory = $true,
            ParameterSetName = 'Path',
            Position = 0,
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

        [Parameter(
            Mandatory = $true,
            ParameterSetName = 'Script',
            Position = 0,
            ValueFromPipeline = $true,
            ValueFromPipelineByPropertyName = $true
        )]
        [Alias('Command')]
        [AllowEmptyString()]
        [string[]]$Script,

        [Parameter()]
        [switch]$Detailed
    )

    process {
        $inputs = @($Script)
        $isFileInput = $PSCmdlet.ParameterSetName -in @('Path', 'LiteralPath')
        if ($isFileInput) {
            $pathParameters = Select-WUBoundParameter `
                -BoundParameters $PSBoundParameters `
                -Name 'Path', 'LiteralPath'
            $inputs = @(
                Resolve-WUExistingFileSystemPath `
                    @pathParameters `
                    -Leaf `
                    -Readable
            )
        }

        foreach ($currentInput in $inputs) {
            $tokens = $null
            $parseErrors = $null
            $reportedInput = $currentInput
            if ($isFileInput) {
                $null = [System.Management.Automation.Language.Parser]::ParseFile(
                    $reportedInput,
                    [ref]$tokens,
                    [ref]$parseErrors
                )
            } else {
                $null = [System.Management.Automation.Language.Parser]::ParseInput(
                    $currentInput,
                    [ref]$tokens,
                    [ref]$parseErrors
                )
            }

            $isValid = @($parseErrors).Count -eq 0
            if ($Detailed) {
                [pscustomobject]@{
                    IsValid = $isValid
                    Input = $reportedInput
                    Errors = @($parseErrors)
                }
            } else {
                $isValid
            }
        }
    }
}
