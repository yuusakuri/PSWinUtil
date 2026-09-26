function Set-WUPersistentEnvironmentVariable {
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute(
        'PSUseShouldProcessForStateChangingFunctions',
        '',
        Justification = 'Set-WUEnvironmentVariable evaluates ShouldProcess before calling this internal function.'
    )]
    [CmdletBinding()]
    [OutputType([bool])]
    param(
        [Parameter(Mandatory = $true)]
        [string]$Name,

        [Parameter(Mandatory = $true)]
        [AllowNull()]
        [AllowEmptyString()]
        [string]$Value,

        [Parameter(Mandatory = $true)]
        [ValidateSet('User', 'Machine')]
        [string]$Scope
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
    $registryKey = $baseKey.CreateSubKey($registryPath)
    try {
        if ([string]::IsNullOrEmpty($Value) -and $null -eq $registryKey.GetValue($Name)) {
            return $false
        }

        if ([string]::IsNullOrEmpty($Value)) {
            $registryKey.DeleteValue($Name, $false)
            return $true
        }

        $valueKind = if ($Value -match '%[^%]+%') {
            [Microsoft.Win32.RegistryValueKind]::ExpandString
        } else {
            [Microsoft.Win32.RegistryValueKind]::String
        }
        $registryKey.SetValue($Name, $Value, $valueKind)
        $true
    } finally {
        $registryKey.Dispose()
    }
}
