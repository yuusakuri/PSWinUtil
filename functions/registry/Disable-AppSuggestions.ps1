function Disable-WUAppSuggestions {
    [CmdletBinding(SupportsShouldProcess)]
    param (
    )

    Set-StrictMode -Version 'Latest'
    $registryHash = Get-WURegistryHash
    if (!$registryHash) {
        return
    }

    Set-WURegistryFromHash -RegistryHash $registryHash -DataKey $MyInvocation.MyCommand.Verb
}
