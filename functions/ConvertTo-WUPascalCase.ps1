<#
    .SYNOPSIS
    Converts the beginning of each string separated by spaces, underscores, or hyphens to uppercase, and removes spaces.

    .DESCRIPTION
    Converts the beginning of each string separated by spaces, underscores, or hyphens to uppercase, and removes spaces.

    .OUTPUTS
    System.String

    .EXAMPLE
    PS C:\>ConvertTo-WUPascalCase -String 'apple_orange-CHERRY melon'
    returns 'AppleOrangeCHERRYMelon'
#>

[CmdletBinding()]
param (
    # Specify the string to be converted to Pascal Case.
    [Parameter(Mandatory,
        Position = 0,
        ValueFromPipeline,
        ValueFromPipelineByPropertyName)]
    [ValidateNotNullOrEmpty()]
    [string]
    $String
)

$words = [regex]::Replace($String, '\W|_|-', "`n") -split ("`n")

$newString = ''
foreach ($word in $words) {
    $newWord = '{0}{1}' -f $word.Substring(0, 1).ToUpper(), $word.Remove(0, 1)
    $newString = '{0}{1}' -f $newString, $newWord
}

return $newString
