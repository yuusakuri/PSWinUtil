<#
    .SYNOPSIS
    Get a random string.

    .DESCRIPTION
    Get a random string. You can specify the number of characters and character types.

    .OUTPUTS
    System.String

    .EXAMPLE
    PS C:\>Get-WURandomString -Length 8

    Returns a string like '8i60va7z'.

    .EXAMPLE
    PS C:\>Get-WURandomString -Length 32 -CharType 'UppercaseAlphabet','Number'

    Returns a string like '3EU1PZ4YQLC2SIJMON0W8BTG7H5A9X6K'.

    .EXAMPLE
    PS C:\>Get-WURandomString -Length 16 -Char '_','@','[',']'

    Returns a string like 'd[7e3x5wqi8nztl_'.
#>

[CmdletBinding()]
param (
    [ValidateNotNullOrEmpty()]
    [int]
    # Specify the number of characters to retrieve.
    $Length,

    [ValidateSet('Number', 'LowercaseAlphabet', 'UppercaseAlphabet')]
    [string[]]
    # Specifies character types. The default value are 'Number', 'LowercaseAlphabet'.
    $CharType = @('Number', 'LowercaseAlphabet'),

    [char[]]
    $Char
)

Set-StrictMode -Version 'Latest'

$CharTypeRanges = @{
    Number            = 48..57
    LowercaseAlphabet = 97..122
    UppercaseAlphabet = 65..90
}

$CharRanges = $CharType | ForEach-Object {
    $CharTypeRanges.$_
}

$CharRanges += [int[]]$Char

return -join (
    $CharRanges |
    Select-Object -Unique |
    Get-Random -Count $Length |
    ForEach-Object { [char]$_ }
)
