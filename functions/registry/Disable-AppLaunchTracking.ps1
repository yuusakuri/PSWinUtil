﻿function Disable-WUAppLaunchTracking {
    [CmdletBinding(SupportsShouldProcess)]
    param (
        # Specifies the scope that is affected. The default scope is CurrentUser.
        [ValidateSet('CurrentUser', 'LocalMachine')]
        [string]
        $Scope = 'CurrentUser'
    )

    Set-StrictMode -Version 'Latest'
    $registryHash = Get-WURegistryHash
    if (!$registryHash) {
        return
    }

    Set-WURegistryFromHash -RegistryHash $registryHash -Scope $Scope -DataKey $MyInvocation.MyCommand.Verb
}
