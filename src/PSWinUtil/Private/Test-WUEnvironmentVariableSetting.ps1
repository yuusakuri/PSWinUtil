function Test-WUEnvironmentVariableSetting {
    <#
    .SYNOPSIS
    Tests environment variable setting data.

    .DESCRIPTION
    Tests that the setting root is a Hashtable, every key is a valid environment variable name, and every value is a string.

    .PARAMETER Setting
    Specifies the imported environment variable setting data to test.

    .EXAMPLE
    Test-WUEnvironmentVariableSetting -Setting @{ JAVA_HOME = 'C:\Java' }

    Returns true for valid environment variable setting data.

    .INPUTS
    None

    .OUTPUTS
    System.Boolean
    #>
    [CmdletBinding()]
    [OutputType([bool])]
    param(
        [Parameter(Mandatory = $true)]
        [AllowNull()]
        [object]$Setting
    )

    if ($Setting -isnot [System.Collections.Hashtable]) {
        return $false
    }

    foreach ($environmentEntry in $Setting.GetEnumerator()) {
        if (
            $environmentEntry.Key -isnot [string] -or
            [string]::IsNullOrEmpty($environmentEntry.Key) -or
            $environmentEntry.Key.IndexOf([char]'=') -ge 0 -or
            $environmentEntry.Key.IndexOf([char]0) -ge 0 -or
            $environmentEntry.Value -isnot [string]
        ) {
            return $false
        }
    }

    $true
}
