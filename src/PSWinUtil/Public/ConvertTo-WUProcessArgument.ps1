function ConvertTo-WUProcessArgument {
    <#
    .SYNOPSIS
    Quotes arguments for a Windows process command line.

    .DESCRIPTION
    Converts each argument to the quoting form used by Windows process argument parsers. Use the result when assigning ProcessStartInfo.Arguments or constructing one Start-Process ArgumentList string.

    .PARAMETER Argument
    Specifies one or more argument values to quote.

    .EXAMPLE
    'install', 'C:\Program Files\App' | ConvertTo-WUProcessArgument

    Quotes each value as a separate Windows process argument.

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
            if ($inputArgument.IndexOf([char]0) -ge 0) {
                throw 'A process argument cannot contain a null character.'
            }

            ConvertTo-WUWindowsCommandLineArgument -Argument $inputArgument
        }
    }
}
