function Assert-WUPSScript {
    <#
    .SYNOPSIS
    Requires valid PowerShell script syntax.

    .DESCRIPTION
    Uses Test-WUPSScript with the parser from the current PowerShell process. Parser errors are reported as an error. Successful checks produce no output.

    .PARAMETER Path
    Specifies one or more PowerShell script files to parse. Wildcards are supported.

    .PARAMETER LiteralPath
    Specifies one or more PowerShell script files to parse without wildcard interpretation.

    .PARAMETER Script
    Specifies PowerShell script text to parse.

    .EXAMPLE
    Assert-WUPSScript -Path '.\install.ps1'

    Completes without output when install.ps1 has valid syntax.

    .EXAMPLE
    Assert-WUPSScript -Script 'if ('

    Reports the parser errors for the incomplete statement.

    .EXAMPLE
    Assert-WUPSScript -LiteralPath '.\install[local].ps1'

    Completes without output when the exact script file has valid syntax.

    .INPUTS
    System.String

    .OUTPUTS
    None
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
        [string[]]$Script
    )

    process {
        $testParameters = @{
            Detailed = $true
        }
        if ($PSCmdlet.ParameterSetName -eq 'Path') {
            $testParameters.Path = $Path
        } elseif ($PSCmdlet.ParameterSetName -eq 'LiteralPath') {
            $testParameters.LiteralPath = $LiteralPath
        } else {
            $testParameters.Script = $Script
        }

        foreach ($result in @(Test-WUPSScript @testParameters)) {
            if (-not $result.IsValid) {
                $messages = @($result.Errors | ForEach-Object { $_.Message }) -join [Environment]::NewLine
                throw "PowerShell parser errors were found:$([Environment]::NewLine)$messages"
            }
        }
    }
}
