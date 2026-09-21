function Update-WUProcessEnvironment {
    <#
    .SYNOPSIS
    Reloads Machine and User environment variables into the current PowerShell process.

    .DESCRIPTION
    Updates the current PowerShell process from Machine and User environment variables. User values override Machine values with the same name. Expandable values use their respective Windows environment blocks. Machine and User PATH values are combined in that order. Variables that exist only in the current process are preserved.

    .EXAMPLE
    Update-WUProcessEnvironment

    Updates the current process environment from the persistent environment variables.

    .EXAMPLE
    Update-WUProcessEnvironment -WhatIf

    Shows whether the current process environment would be updated.

    .INPUTS
    None

    .OUTPUTS
    None
    #>
    [CmdletBinding(SupportsShouldProcess = $true)]
    param()

    $environmentValues = @{}
    $pathValues = @()
    foreach ($targetScope in @('Machine', 'User')) {
        $registryPath = if ($targetScope -eq 'User') {
            'Environment'
        } else {
            'SYSTEM\CurrentControlSet\Control\Session Manager\Environment'
        }
        $baseKey = if ($targetScope -eq 'User') {
            [Microsoft.Win32.Registry]::CurrentUser
        } else {
            [Microsoft.Win32.Registry]::LocalMachine
        }
        $registryKey = $baseKey.OpenSubKey($registryPath, $false)
        if ($null -eq $registryKey) {
            continue
        }
        try {
            $environmentNames = $registryKey.GetValueNames()
        } finally {
            $registryKey.Dispose()
        }
        foreach ($environmentName in $environmentNames) {
            $value = Get-WUEnvironmentVariable -Name $environmentName -Scope $targetScope
            if ($environmentName -ieq 'Path') {
                if (-not [string]::IsNullOrEmpty($value)) {
                    $pathValues += $value
                }
            } else {
                $environmentValues[$environmentName] = $value
            }
        }
    }
    $environmentValues['Path'] = $pathValues -join ';'

    $processTarget = [System.EnvironmentVariableTarget]::Process
    $changes = @()
    foreach ($environmentName in @($environmentValues.Keys | Sort-Object)) {
        $currentValue = [System.Environment]::GetEnvironmentVariable($environmentName, $processTarget)
        $updatedValue = $environmentValues[$environmentName]
        if ($currentValue -cne $updatedValue) {
            $changes += [pscustomobject]@{
                Name = $environmentName
                Value = $updatedValue
            }
        }
    }

    if ($changes.Count -eq 0) {
        return
    }

    $targetDescription = 'current PowerShell process environment'
    $actionDescription = 'Update from Machine and User environment variables'
    if (-not $PSCmdlet.ShouldProcess($targetDescription, $actionDescription)) {
        return
    }

    foreach ($change in $changes) {
        [System.Environment]::SetEnvironmentVariable(
            $change.Name,
            $change.Value,
            $processTarget
        )
    }
}
