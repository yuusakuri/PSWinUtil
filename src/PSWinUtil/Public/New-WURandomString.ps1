function New-WURandomString {
    <#
    .SYNOPSIS
    Creates a cryptographically random string.

    .DESCRIPTION
    Creates a string from uppercase letters, lowercase letters, and digits. RandomNumberGenerator is used with rejection sampling to avoid selection bias.

    .PARAMETER Length
    Specifies the number of characters to create.

    .EXAMPLE
    New-WURandomString -Length 32

    Returns a 32-character string containing only letters and digits.

    .EXAMPLE
    New-WURandomString -Length 0

    Reports a parameter validation error because Length must be at least one.

    .OUTPUTS
    System.String
    #>
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute(
        'PSUseShouldProcessForStateChangingFunctions',
        '',
        Justification = 'The function creates a string and does not change external state.'
    )]
    [CmdletBinding()]
    [OutputType([string])]
    param(
        [Parameter(Mandatory = $true, Position = 0)]
        [ValidateRange(1, [int]::MaxValue)]
        [int]$Length
    )

    $characters = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789'
    $characterCount = $characters.Length
    $maximumAcceptedByte = [int]([math]::Floor(256 / $characterCount) * $characterCount)
    $builder = [System.Text.StringBuilder]::new($Length)
    $randomNumberGenerator = [System.Security.Cryptography.RandomNumberGenerator]::Create()
    $randomByte = [byte[]]::new(1)
    try {
        while ($builder.Length -lt $Length) {
            $randomNumberGenerator.GetBytes($randomByte)
            if ($randomByte[0] -ge $maximumAcceptedByte) {
                continue
            }

            $characterIndex = [int]($randomByte[0] % $characterCount)
            $null = $builder.Append($characters[$characterIndex])
        }
    } finally {
        $randomNumberGenerator.Dispose()
    }

    $builder.ToString()
}
