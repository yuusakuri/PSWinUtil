$script:WUCommandOverrideDefinition = @{}
foreach ($overrideName in @(Get-WUCommandOverrideName)) {
    $overridePath = "Function:\$overrideName"
    $script:WUCommandOverrideDefinition[$overrideName] = (
        Microsoft.PowerShell.Management\Get-Item -LiteralPath $overridePath
    ).ScriptBlock
    Microsoft.PowerShell.Management\Remove-Item -LiteralPath $overridePath -Force
}

if ($PSVersionTable.PSEdition -eq 'Desktop') {
    Set-WUCommandOverride -Name @(Get-WUCommandOverrideName) -Enabled

    $MyInvocation.MyCommand.ScriptBlock.Module.OnRemove = {
        Set-WUCommandOverride -Name @(Get-WUCommandOverrideName) -Enabled:$false
    }
} else {
    foreach ($overrideCommandName in @('Enable-WUCommandOverride', 'Disable-WUCommandOverride')) {
        Microsoft.PowerShell.Management\Remove-Item -LiteralPath "Function:\$overrideCommandName" -Force
    }
}
