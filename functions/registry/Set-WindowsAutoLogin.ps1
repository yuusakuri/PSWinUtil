function Set-WUWindowsAutoLogin {
    [CmdletBinding(SupportsShouldProcess)]
    param (
        [string]
        $Username,

        [string]
        $Password
    )

    Set-StrictMode -Version 'Latest'
    $registryHash = Get-WURegistryHash
    if (!$registryHash) {
        return
    }

    $registryHash.Username.LocalMachine.Data = $Username
    $registryHash.Password.LocalMachine.Data = $Password

    if ($Username) {
        $registryHash.Enable1.LocalMachine.Data = $registryHash.Enable1.LocalMachine.Data.Enable
        $registryHash.Enable2.LocalMachine.Data = $registryHash.Enable2.LocalMachine.Data.Enable
    }
    else {
        $registryHash.Enable1.LocalMachine.Data = $registryHash.Enable1.LocalMachine.Data.Disable
        $registryHash.Enable2.LocalMachine.Data = $registryHash.Enable2.LocalMachine.Data.Disable
    }

    Set-WURegistryFromHash -RegistryHash $registryHash
}
