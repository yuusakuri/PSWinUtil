function Set-WUPS1Action {
    [CmdletBinding(SupportsShouldProcess)]
    param (
        [ValidateSet('Run', 'Edit', 'Notepad')]
        [string]
        $PS1Action
    )

    Set-StrictMode -Version 'Latest'
    $registryHash = Get-WURegistryHash
    if (!$registryHash) {
        return
    }

    Set-WURegistryFromHash -RegistryHash $registryHash -DataKey $PS1Action
}
