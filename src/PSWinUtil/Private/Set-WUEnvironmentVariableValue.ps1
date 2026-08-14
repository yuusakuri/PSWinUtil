function Set-WUEnvironmentVariableValue {
    [CmdletBinding(
        DefaultParameterSetName = 'Set',
        SupportsShouldProcess = $true
    )]
    param(
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [ValidatePattern('^[^=\x00]+$')]
        [string]$Name,

        [Parameter(Mandatory = $true, ParameterSetName = 'Set')]
        [AllowEmptyString()]
        [string]$Value,

        [Parameter(Mandatory = $true, ParameterSetName = 'Remove')]
        [switch]$Remove,

        [Parameter(Mandatory = $true)]
        [ValidateSet('Process', 'User', 'Machine')]
        [string]$Scope
    )

    $target = [System.EnvironmentVariableTarget]$Scope
    $targetDescription = "$Scope environment variable '$Name'"
    $action = 'Set environment variable'
    $valueToSet = $null
    if ($PSCmdlet.ParameterSetName -eq 'Set') {
        $valueToSet = $Value
    } elseif ($Remove) {
        $action = 'Remove environment variable'
    }

    if ($PSCmdlet.ShouldProcess($targetDescription, $action)) {
        [System.Environment]::SetEnvironmentVariable($Name, $valueToSet, $target)
    }
}
