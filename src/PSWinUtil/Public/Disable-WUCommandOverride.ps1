function Disable-WUCommandOverride {
    <#
    .SYNOPSIS
    Disables command overrides.

    .DESCRIPTION
    Removes the PSWinUtil proxy function of each requested command from the PowerShell session, so PowerShell resolves the command with its original cmdlet and its original defaults. Get-Content, Set-Content, Add-Content, and Out-File can be requested, on their own or together. A command that is already disabled is left as it is, and a command that is not requested is not changed.

    .PARAMETER Name
    Specifies one or more of Get-Content, Set-Content, Add-Content, and Out-File.

    .EXAMPLE
    Disable-WUCommandOverride -Name Get-Content

    Resolves Get-Content with the original cmdlet.

    .EXAMPLE
    Disable-WUCommandOverride -Name Get-Content, Set-Content, Add-Content, Out-File

    Resolves every overridden command with its original cmdlet.

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
        Set-WUCommandOverride -Name $Name -Enabled:$false @shouldProcessParameters
    }
}
