function Convert-WUString {
    <#
        .SYNOPSIS
        Convert strings for a specific purpose.

        .DESCRIPTION
        Convert strings for a specific purpose.

        .EXAMPLE
        PS C:\>Convert-WUString -String ('{0}{1}' -f [char]0xFF11, [char]0xFF12) -Type FullWidthNumberToHalfWidthNumber
        12

        .EXAMPLE
        PS C:\>Convert-WUString -String ('{0}{1}' -f [char]0xFF21, [char]0xFF41) -Type FullWidthAlphabetToHalfWidthAlphabet
        Aa

        .EXAMPLE
        PS C:\>Convert-WUString -String 'apple_orange-CHERRY melon' -Type FullWidthNumberToHalfWidthNumber
        AppleOrangeCHERRYMelon

        .EXAMPLE
        PS C:\>Convert-WUString -String ('a`$a{0}{1}{2}"' -f [char]0x201C, [char]0x201D, [char]0x201E) -Type EscapeForPowerShellDoubleQuotation
    #>

    [CmdletBinding()]
    param (
        # Specifies the strings to convert.
        [Parameter(Mandatory,
            Position = 0,
            ValueFromPipeline,
            ValueFromPipelineByPropertyName)]
        [ValidateNotNullOrEmpty()]
        [string[]]
        $String,

        # If FullWidthNumberToHalfWidthNumber is specified, convert full width number to half width number.
        # If FullWidthAlphabetToHalfWidthAlphabet is specified, convert full width alphabet to half width alphabet.
        # If UpperCamelCase or LowerCamelCase is specified, converts the beginning of each string separated by spaces, underscores, or hyphens to uppercase, and removes spaces, underscores, and hyphens. However, the first letter of LowerCamelCase is lowercase.
        # If EscapeForPowerShellDoubleQuotation is specified, escape Quotation mark (U+0022), Dollar sign (U+0024), Grave accent (U+0060), Left double quotation mark (U+201C), Right double quotation mark (U+201D), Double low-9 quotation mark (U+201E) for PowerShell doubleQuotation.
        [Parameter(Mandatory)]
        [ValidateSet('FullWidthNumberToHalfWidthNumber',
            'FullWidthAlphabetToHalfWidthAlphabet',
            'UpperCamelCase',
            'LowerCamelCase',
            'EscapeForPowerShellDoubleQuotation')]
        [string]
        $Type
    )

    begin {
        Set-StrictMode -Version 'Latest'
    }

    process {
        foreach ($aString in $String) {
            switch -Regex ($Type) {
                'FullWidthNumberToHalfWidthNumber' {
                    $aString `
                        -creplace [char]0xFF10, "0" `
                        -creplace [char]0xFF11, "1" `
                        -creplace [char]0xFF12, "2" `
                        -creplace [char]0xFF13, "3" `
                        -creplace [char]0xFF14, "4" `
                        -creplace [char]0xFF15, "5" `
                        -creplace [char]0xFF16, "6" `
                        -creplace [char]0xFF17, "7" `
                        -creplace [char]0xFF18, "8" `
                        -creplace [char]0xFF19, "9"
                    break
                }
                'FullWidthAlphabetToHalfWidthAlphabet' {
                    $aString `
                        -creplace [char]0xFF21, "A" `
                        -creplace [char]0xFF22, "B" `
                        -creplace [char]0xFF23, "C" `
                        -creplace [char]0xFF24, "D" `
                        -creplace [char]0xFF25, "E" `
                        -creplace [char]0xFF26, "F" `
                        -creplace [char]0xFF27, "G" `
                        -creplace [char]0xFF28, "H" `
                        -creplace [char]0xFF29, "I" `
                        -creplace [char]0xFF2A, "J" `
                        -creplace [char]0xFF2B, "K" `
                        -creplace [char]0xFF2C, "L" `
                        -creplace [char]0xFF2D, "M" `
                        -creplace [char]0xFF2E, "N" `
                        -creplace [char]0xFF2F, "O" `
                        -creplace [char]0xFF30, "P" `
                        -creplace [char]0xFF31, "Q" `
                        -creplace [char]0xFF32, "R" `
                        -creplace [char]0xFF33, "S" `
                        -creplace [char]0xFF34, "T" `
                        -creplace [char]0xFF35, "U" `
                        -creplace [char]0xFF36, "V" `
                        -creplace [char]0xFF37, "W" `
                        -creplace [char]0xFF38, "X" `
                        -creplace [char]0xFF39, "Y" `
                        -creplace [char]0xFF3A, "Z" `
                        -creplace [char]0xFF41, "a" `
                        -creplace [char]0xFF42, "b" `
                        -creplace [char]0xFF43, "c" `
                        -creplace [char]0xFF44, "d" `
                        -creplace [char]0xFF45, "e" `
                        -creplace [char]0xFF46, "f" `
                        -creplace [char]0xFF47, "g" `
                        -creplace [char]0xFF48, "h" `
                        -creplace [char]0xFF49, "i" `
                        -creplace [char]0xFF4A, "j" `
                        -creplace [char]0xFF4B, "k" `
                        -creplace [char]0xFF4C, "l" `
                        -creplace [char]0xFF4D, "m" `
                        -creplace [char]0xFF4E, "n" `
                        -creplace [char]0xFF4F, "o" `
                        -creplace [char]0xFF50, "p" `
                        -creplace [char]0xFF51, "q" `
                        -creplace [char]0xFF52, "r" `
                        -creplace [char]0xFF53, "s" `
                        -creplace [char]0xFF54, "t" `
                        -creplace [char]0xFF55, "u" `
                        -creplace [char]0xFF56, "v" `
                        -creplace [char]0xFF57, "w" `
                        -creplace [char]0xFF58, "x" `
                        -creplace [char]0xFF59, "y" `
                        -creplace [char]0xFF5A, "z"
                    break
                }
                'UpperCamelCase|LowerCamelCase' {
                    [string[]]$words = $aString -split ("`n|`r`n|\W|_|-") |
                    Where-Object { !($_ -match '^\s*$') }

                    $aNewString = ''
                    for ($i = 0; $i -lt $words.Count; $i++) {
                        $aWord = $words[$i]

                        if ($i -eq 0) {
                            if ($Type -eq 'UpperCamelCase') {
                                $newWord = '{0}{1}' -f $aWord.Substring(0, 1).ToUpper(), $aWord.Remove(0, 1)
                            }
                            if ($Type -eq 'LowerCamelCase') {
                                $newWord = '{0}{1}' -f $aWord.Substring(0, 1).ToLower(), $aWord.Remove(0, 1)
                            }
                        }
                        else {
                            $newWord = '{0}{1}' -f $aWord.Substring(0, 1).ToUpper(), $aWord.Remove(0, 1)
                        }

                        $aNewString = '{0}{1}' -f $aNewString, $newWord
                    }

                    $aNewString
                    break
                }
                'EscapeForPowerShellDoubleQuotation' {
                    $aString `
                        -creplace '"', '""' `
                        -creplace '`', '``' `
                        -creplace '\$', '`$' `
                        -creplace [char]0x201C, ('`{0}' -f [char]0x201C) `
                        -creplace [char]0x201D, ('`{0}' -f [char]0x201D) `
                        -creplace [char]0x201E, ('`{0}' -f [char]0x201E)
                    break
                }
            }
        }
    }
}
