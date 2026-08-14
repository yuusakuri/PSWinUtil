function Assert-WUPSScript {
    <#
    .SYNOPSIS
    Requires valid PowerShell script syntax.

    .DESCRIPTION
    Uses Test-WUPSScript with the parser from the current PowerShell process. Parser errors are reported as an error. Successful checks produce no output.

    .PARAMETER Path
    Specifies one or more PowerShell script files to parse.

    .PARAMETER Script
    Specifies PowerShell script text to parse.

    .EXAMPLE
    Assert-WUPSScript -Path '.\install.ps1'

    Completes without output when install.ps1 has valid syntax.

    .EXAMPLE
    Assert-WUPSScript -Script 'if ('

    Reports the parser errors for the incomplete statement.

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
        [string[]]$Path,

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
        $inputs = $Script
        if ($PSCmdlet.ParameterSetName -eq 'Path') {
            $inputs = $Path
        }

        foreach ($currentInput in $inputs) {
            if ($PSCmdlet.ParameterSetName -eq 'Path') {
                $result = Test-WUPSScript -Path $currentInput -Detailed
            } else {
                $result = Test-WUPSScript -Script $currentInput -Detailed
            }

            if (-not $result.IsValid) {
                $messages = @($result.Errors | ForEach-Object { $_.Message }) -join [Environment]::NewLine
                throw "PowerShell parser errors were found:$([Environment]::NewLine)$messages"
            }
        }
    }
}
