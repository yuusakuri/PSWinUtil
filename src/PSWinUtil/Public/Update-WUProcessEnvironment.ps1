function Update-WUProcessEnvironment {
    <#
    .SYNOPSIS
    Reloads Machine and User environment variables into the current PowerShell process.

    .DESCRIPTION
    Updates the current PowerShell process from Machine and User environment variables. User values override Machine values with the same name. Machine and User PATH values are expanded using their respective Windows environment blocks and combined in that order. Variables that exist only in the current process are preserved.

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
    foreach ($target in @(
            [System.EnvironmentVariableTarget]::Machine,
            [System.EnvironmentVariableTarget]::User
        )) {
        $targetEnvironment = [System.Environment]::GetEnvironmentVariables($target)
        foreach ($environmentName in $targetEnvironment.Keys) {
            if ([string]$environmentName -ieq 'Path') {
                continue
            }

            $environmentValues[[string]$environmentName] = [PSWinUtil.EnvironmentVariableExpander]::Expand(
                "%$environmentName%",
                [string]$target
            )
        }
    }

    $pathValues = @()
    foreach ($target in @(
            [System.EnvironmentVariableTarget]::Machine,
            [System.EnvironmentVariableTarget]::User
        )) {
        $pathValue = Get-WUEnvironmentVariable -Name 'Path' -Scope ([string]$target) -NoExpand
        if (-not [string]::IsNullOrEmpty($pathValue)) {
            $pathValues += [PSWinUtil.EnvironmentVariableExpander]::Expand($pathValue, [string]$target)
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
