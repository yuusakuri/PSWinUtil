function Enable-WUSystemSounds {
    [CmdletBinding(SupportsShouldProcess)]
    param (
    )

    Set-StrictMode -Version 'Latest'
    $registryHash = Get-WURegistryHash
    if (!$registryHash) {
        return
    }

    Set-WURegistryFromHash -RegistryHash $registryHash -DataKey $MyInvocation.MyCommand.Verb

    Get-ChildItem -Path "HKCU:\AppEvents\Schemes\Apps" |
    Get-ChildItem |
    ForEach-Object {
        $value = Get-ChildItem $_.PSPath | Where-Object { $_.PSChildName -eq ".default" } |
        Get-ItemProperty | Where-Object { $_ | Get-Member -Name "(Default)" } |
        Get-ItemPropertyValue -Name "(Default)"

        Get-ChildItem  $_.PSPath | Where-Object { $_.PSChildName -eq ".Current" } |
        Get-ItemProperty | Where-Object { $_ | Get-Member -Name "(Default)" } |
        Set-ItemProperty -Name "(Default)" -Value $value
    }
}
