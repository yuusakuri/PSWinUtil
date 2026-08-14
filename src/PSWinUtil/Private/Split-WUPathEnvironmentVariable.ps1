function Split-WUPathEnvironmentVariable {
    [CmdletBinding()]
    [OutputType([string])]
    param(
        [Parameter(Mandatory = $true)]
        [AllowNull()]
        [AllowEmptyString()]
        [string]$Value
    )

    if ([string]::IsNullOrWhiteSpace($Value)) {
        return
    }

    foreach ($pathItem in $Value.Split([char]';')) {
        $trimmedPath = $pathItem.Trim()
        if (-not [string]::IsNullOrWhiteSpace($trimmedPath)) {
            $trimmedPath
        }
    }
}
