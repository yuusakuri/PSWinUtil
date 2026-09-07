function Set-WUCommandOverride {
    <#
    .SYNOPSIS
    Places or removes command override proxy functions.

    .DESCRIPTION
    Writes each requested proxy function into the session when Enabled is specified, and removes it when Enabled is omitted. A command whose proxy function is absent is resolved by the original PowerShell cmdlet, so the presence of the proxy function is the override state itself. A name that PSWinUtil does not override is rejected, and a command that already has the requested state is left as it is.

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

    $overrideNames = @(Get-WUCommandOverrideName)
    foreach ($commandName in $Name) {
        if ($commandName -notin $overrideNames) {
            throw "The command override was not found: $commandName. PSWinUtil overrides $($overrideNames -join ', ')."
        }
    }

    $action = 'Remove the command override proxy'
    if ($Enabled) {
        $action = 'Place the command override proxy'
    }

    foreach ($commandName in @($Name | Select-Object -Unique)) {
        if (-not $PSCmdlet.ShouldProcess($commandName, $action)) {
            continue
        }

        $functionPath = "Function:\$commandName"
        if ($Enabled) {
            Microsoft.PowerShell.Management\Set-Item `
                -Path "function:global:$commandName" `
                -Value $script:WUCommandOverrideDefinition[$commandName]
        } elseif (Microsoft.PowerShell.Management\Test-Path -LiteralPath $functionPath) {
            Microsoft.PowerShell.Management\Remove-Item -LiteralPath $functionPath -Force
        }
    }
}
