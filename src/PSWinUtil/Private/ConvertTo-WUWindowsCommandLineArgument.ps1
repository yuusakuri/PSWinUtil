function ConvertTo-WUWindowsCommandLineArgument {
    <#
    .SYNOPSIS
    Quotes one Windows command-line argument.

    .DESCRIPTION
    Converts one argument to the quoting form used by Windows command-line parsers. Backslashes before quotation marks and at the end of a quoted argument are escaped.

    .PARAMETER Argument
    Specifies the argument text.

    .PARAMETER AlwaysQuote
    Encloses the argument in quotation marks even when quoting is not otherwise required.

    .EXAMPLE
    ConvertTo-WUWindowsCommandLineArgument -Argument 'C:\Program Files\Example\app.exe' -AlwaysQuote

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

    if (-not $AlwaysQuote -and $Argument.Length -gt 0 -and $Argument -notmatch '[\s"]') {
        $Argument
        return
    }

    $builder = [System.Text.StringBuilder]::new()
    $null = $builder.Append([char]34)
    $backslashCount = 0

    foreach ($character in $Argument.ToCharArray()) {
        if ($character -eq [char]92) {
            $backslashCount++
            continue
        }

        if ($character -eq [char]34) {
            $null = $builder.Append([char]92, ($backslashCount * 2) + 1)
            $null = $builder.Append([char]34)
            $backslashCount = 0
            continue
        }

        if ($backslashCount -gt 0) {
            $null = $builder.Append([char]92, $backslashCount)
            $backslashCount = 0
        }
        $null = $builder.Append($character)
    }

    if ($backslashCount -gt 0) {
        $null = $builder.Append([char]92, $backslashCount * 2)
    }
    $null = $builder.Append([char]34)
    $builder.ToString()
}
