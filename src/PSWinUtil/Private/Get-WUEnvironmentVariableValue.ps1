function Get-WUEnvironmentVariableValue {
    [CmdletBinding()]
    [OutputType([string])]
    param(
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [ValidatePattern('^[^=\x00]+$')]
        [string]$Name,

        [Parameter(Mandatory = $true)]
        [ValidateSet('Process', 'User', 'Machine')]
        [string]$Scope
    )

    $target = [System.EnvironmentVariableTarget]$Scope
    [System.Environment]::GetEnvironmentVariable($Name, $target)
}
