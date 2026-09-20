function ConvertTo-WUCmdArgument {
    <#
    .SYNOPSIS
    Quotes supported argument values for a Windows batch command.

    .DESCRIPTION
    Formats values passed to a .cmd or .bat file through cmd.exe. Values containing characters that cmd.exe expands or cannot reliably preserve are rejected.

    .PARAMETER Argument
    Specifies one or more batch command argument values.

    .EXAMPLE
    'install', 'C:\Program Files\App' | ConvertTo-WUCmdArgument

    Quotes each supported value as a separate batch command argument.

    .INPUTS
    System.String

    .OUTPUTS
    System.String
    #>
    [CmdletBinding()]
    [OutputType([string])]
    param(
        [Parameter(Mandatory = $true, Position = 0, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true)]
        [AllowEmptyString()]
        [ValidateNotNull()]
        [string[]]$Argument
    )

    process {
        foreach ($inputArgument in $Argument) {
            if ($inputArgument -match '[\x00-\x1F\x7F"%!]' -or $inputArgument.EndsWith('\')) {
                throw 'A batch command argument cannot contain a control character, double quote, percent sign, exclamation mark, or trailing backslash.'
            }

            if ($inputArgument.Length -eq 0 -or $inputArgument -match '[\s&<>|^()]') {
                '"{0}"' -f $inputArgument
            } else {
                $inputArgument
            }
        }
    }
}
