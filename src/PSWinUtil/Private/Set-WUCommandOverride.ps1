function Set-WUCommandOverride {
    <#
    .SYNOPSIS
    Places or removes command override proxy functions.

    .DESCRIPTION
    Writes each requested proxy function into the session when Enabled is specified, and removes it when Enabled is omitted. A command whose proxy function is absent is resolved by the original PowerShell cmdlet, so the presence of the proxy function is the override state itself. A command that already has the requested state is left as it is. The callers restrict the accepted names, so this function does not check them again.

    Placing a proxy names the global scope in its path, because a path without a scope writes the function into the module. Removing one uses the path without a scope, because PowerShell then searches the scopes in turn and reaches the placed function, while a path that names the global scope removes nothing and reports no error.

    .PARAMETER Name
    Specifies one or more overridden command names.

    .PARAMETER Enabled
    Places the proxy functions. Omit it to remove them.

    .EXAMPLE
    Set-WUCommandOverride -Name 'Get-Content' -Enabled

    Places the Get-Content proxy function into the session.

    .EXAMPLE
    Set-WUCommandOverride -Name 'Get-Content', 'Set-Content' -Enabled:$false

    Removes the Get-Content and Set-Content proxy functions from the session.

    .INPUTS
    None

    .OUTPUTS
    None
    #>
    [CmdletBinding(SupportsShouldProcess = $true)]
    param(
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string[]]$Name,

        [Parameter()]
        [switch]$Enabled
    )

    $action = if ($Enabled) {
        'Place the command override proxy'
    } else {
        'Remove the command override proxy'
    }

    foreach ($commandName in @($Name | Select-Object -Unique)) {
        if (-not $PSCmdlet.ShouldProcess($commandName, $action)) {
            continue
        }

        if ($Enabled) {
            Microsoft.PowerShell.Management\Set-Item `
                -Path "function:global:$commandName" `
                -Value $script:WUCommandOverrideDefinition[$commandName]
        } elseif (Microsoft.PowerShell.Management\Test-Path -LiteralPath "Function:\$commandName") {
            Microsoft.PowerShell.Management\Remove-Item -LiteralPath "Function:\$commandName" -Force
        }
    }
}
