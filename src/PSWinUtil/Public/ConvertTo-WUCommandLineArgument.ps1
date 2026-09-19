function ConvertTo-WUCommandLineArgument {
    <#
    .SYNOPSIS
    Quotes an argument for a Windows executable command line.

    .DESCRIPTION
    Formats one argument for an executable that follows the standard Windows argument parsing rules. Backslashes before quotation marks and at the end of a quoted argument are escaped.

    .PARAMETER Argument
    Specifies the argument text.

    .PARAMETER AlwaysQuote
    Encloses the argument in quotation marks even when quoting is not otherwise required.

    .EXAMPLE
    ConvertTo-WUCommandLineArgument -Argument 'C:\Program Files\Example\app.exe' -AlwaysQuote

    Returns a quoted executable path.

    .INPUTS
    None

    .OUTPUTS
    System.String
    #>
    [CmdletBinding()]
    [OutputType([string])]
    param(
        [Parameter(Mandatory = $true)]
        [AllowEmptyString()]
        [string]$Argument,

        [Parameter()]
        [switch]$AlwaysQuote
    )

    if ($Argument.IndexOf([char]0) -ge 0) {
        throw 'A process argument cannot contain a null character.'
    }

    if (-not $AlwaysQuote -and $Argument.Length -gt 0 -and $Argument -notmatch '[\s"]') {
        $Argument
        return
    }

    $builder = [System.Text.StringBuilder]::new()
    $builder.Append([char]34) | Out-Null
    $backslashCount = 0

    foreach ($character in $Argument.ToCharArray()) {
        if ($character -eq [char]92) {
            $backslashCount++
            continue
        }

        if ($character -eq [char]34) {
            $builder.Append([char]92, ($backslashCount * 2) + 1) | Out-Null
            $builder.Append([char]34) | Out-Null
            $backslashCount = 0
            continue
        }

        if ($backslashCount -gt 0) {
            $builder.Append([char]92, $backslashCount) | Out-Null
            $backslashCount = 0
        }
        $builder.Append($character) | Out-Null
    }

    if ($backslashCount -gt 0) {
        $builder.Append([char]92, $backslashCount * 2) | Out-Null
    }
    $builder.Append([char]34) | Out-Null
    $builder.ToString()
}
