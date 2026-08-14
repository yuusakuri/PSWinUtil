function Join-WUPathEnvironmentVariable {
    [CmdletBinding()]
    [OutputType([string])]
    param(
        [Parameter(Mandatory = $true)]
        [AllowEmptyCollection()]
        [string[]]$Path
    )

    $Path -join ';'
}
