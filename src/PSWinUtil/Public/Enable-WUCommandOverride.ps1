function Enable-WUCommandOverride {
    <#
    .SYNOPSIS
    Enables command overrides.

    .DESCRIPTION
    Places the PSWinUtil proxy function of each requested command into the PowerShell session, so the command uses the PSWinUtil UTF-8 and LF defaults again. Get-Content, Set-Content, Add-Content, and Out-File can be requested, on their own or together. A command that is already enabled is left as it is, and a command that is not requested is not changed.

    .PARAMETER Name
    Specifies one or more of Get-Content, Set-Content, Add-Content, and Out-File.

    .EXAMPLE
    Enable-WUCommandOverride -Name Get-Content

    Uses the PSWinUtil Get-Content behavior again.

    .EXAMPLE
    Enable-WUCommandOverride -Name Get-Content, Set-Content, Add-Content, Out-File

    Uses the PSWinUtil behavior again for every overridden command.

    .INPUTS
    System.String

    .OUTPUTS
    None
    #>
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute(
        'PSShouldProcess',
        '',
        Justification = 'The command override function evaluates ShouldProcess for each delegated change.'
    )]
    [CmdletBinding(SupportsShouldProcess = $true)]
    param(
        [Parameter(Mandatory = $true, Position = 0, ValueFromPipeline = $true)]
        [ValidateSet(
            'Get-Content',
            'Set-Content',
            'Add-Content',
            'Out-File'
        )]
        [string[]]$Name
    )

    process {
        $shouldProcessParameters = Select-WUBoundParameter -BoundParameters $PSBoundParameters -Name 'WhatIf', 'Confirm'
        Set-WUCommandOverride -Name $Name -Enabled @shouldProcessParameters
    }
}
