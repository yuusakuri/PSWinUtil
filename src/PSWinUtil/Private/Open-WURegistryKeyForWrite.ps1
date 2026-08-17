function Open-WURegistryKeyForWrite {
    <#
    .SYNOPSIS
    Opens a registry key for writing.

    .DESCRIPTION
    Converts a supported registry provider path to a Microsoft.Win32.RegistryKey and opens the existing key with write access. The caller must dispose the returned key.

    .PARAMETER Path
    Specifies an existing HKEY_CURRENT_USER, HKEY_LOCAL_MACHINE, or HKEY_CURRENT_CONFIG registry provider path.

    .EXAMPLE
    $key = Open-WURegistryKeyForWrite `
        -Path 'Registry::HKEY_CURRENT_USER\Software\Example'

    Opens the Example key for writing.

    .INPUTS
    None

    .OUTPUTS
    Microsoft.Win32.RegistryKey
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [ValidatePattern('^Registry::HKEY_(CURRENT_USER|LOCAL_MACHINE|CURRENT_CONFIG)\\.+')]
        [string]$Path
    )

    $hives = @{
        'Registry::HKEY_CURRENT_USER\' = [Microsoft.Win32.Registry]::CurrentUser
        'Registry::HKEY_LOCAL_MACHINE\' = [Microsoft.Win32.Registry]::LocalMachine
        'Registry::HKEY_CURRENT_CONFIG\' = [Microsoft.Win32.Registry]::CurrentConfig
    }

    foreach ($prefix in $hives.Keys) {
        if ($Path.StartsWith($prefix, [System.StringComparison]::OrdinalIgnoreCase)) {
            $subKeyPath = $Path.Substring($prefix.Length)
            $registryKey = $hives[$prefix].OpenSubKey($subKeyPath, $true)
            if ($null -eq $registryKey) {
                throw "Registry key '$Path' could not be opened for writing."
            }
            return $registryKey
        }
    }

    throw "Registry path '$Path' is not supported."
}
