function New-WUCmdArgument {
    <#
    .SYNOPSIS
    Creates a cmd.exe argument string for a Windows batch command.

    .DESCRIPTION
    Builds the complete cmd.exe argument string for running a .cmd or .bat file with supported argument values. Use the result with ProcessStartInfo.Arguments.

    .PARAMETER CommandPath
    Specifies the path of the batch command.

    .PARAMETER ArgumentList
    Specifies the values passed to the batch command.

    .EXAMPLE
    New-WUCmdArgument -CommandPath 'C:\Program Files\Tool\tool.cmd' -ArgumentList @('install', 'C:\Program Files\App')

    Creates the cmd.exe arguments for the tool and its two values.

    .OUTPUTS
    System.String
    #>
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute(
        'PSUseShouldProcessForStateChangingFunctions',
        '',
        Justification = 'The function formats a string without changing state.'
    )]
    [CmdletBinding()]
    [OutputType([string])]
    param(
        [Parameter(Mandatory = $true, Position = 0)]
        [ValidateNotNullOrEmpty()]
        [string]$CommandPath,

        [Parameter(Position = 1)]
        [AllowEmptyCollection()]
        [AllowEmptyString()]
        [string[]]$ArgumentList = @()
    )

    if ($CommandPath -match '[\x00-\x1F\x7F"%!]') {
        throw 'The batch command path is invalid.'
    }

    $arguments = @($ArgumentList | ConvertTo-WUCmdArgument)
    $result = '/e:on /v:off /d /c ""{0}"' -f $CommandPath
    if ($arguments.Count -gt 0) {
        $result += ' ' + ($arguments -join ' ')
    }
    $result + '"'
}
