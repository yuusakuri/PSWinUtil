function Set-WUSearchBoxTaskbarMode {
    [CmdletBinding(SupportsShouldProcess)]
    param (
        [string]
        [ValidateSet('Box', 'Icon', 'None')]
        $Mode
    )

    Set-StrictMode -Version 'Latest'
    $registryHash = Get-WURegistryHash
    if (!$registryHash) {
        return
    }

    Set-WURegistryFromHash -RegistryHash $registryHash -DataKey $Mode
}
