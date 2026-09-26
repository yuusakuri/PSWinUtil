function Get-WUPersistentEnvironmentVariable {
    [CmdletBinding()]
    [OutputType([string])]
    param(
        [Parameter(Mandatory = $true)]
        [string]$Name,

        [Parameter(Mandatory = $true)]
        [ValidateSet('User', 'Machine')]
        [string]$Scope,

        [Parameter()]
        [switch]$NoExpand
    )

    $registryPath = if ($Scope -eq 'User') {
        'Environment'
    } else {
        'SYSTEM\CurrentControlSet\Control\Session Manager\Environment'
    }
    $baseKey = if ($Scope -eq 'User') {
        [Microsoft.Win32.Registry]::CurrentUser
    } else {
        [Microsoft.Win32.Registry]::LocalMachine
    }
    $registryKey = $baseKey.OpenSubKey($registryPath, $false)
    if ($null -eq $registryKey) {
        return
    }

    try {
        $storedValue = $registryKey.GetValue(
            $Name,
            $null,
            [Microsoft.Win32.RegistryValueOptions]::DoNotExpandEnvironmentNames
        )
        if ($null -eq $storedValue) {
            return
        }

        if (-not $NoExpand -and $registryKey.GetValueKind($Name) -eq [Microsoft.Win32.RegistryValueKind]::ExpandString) {
            [PSWinUtil.EnvironmentVariableExpander]::Expand($storedValue, $Scope)
        } else {
            $storedValue
        }
    } finally {
        $registryKey.Dispose()
    }
}
