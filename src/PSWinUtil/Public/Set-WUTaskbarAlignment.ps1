function Set-WUTaskbarAlignment {
    <#
    .SYNOPSIS
    Sets the Windows 11 taskbar alignment.

    .DESCRIPTION
    Sets the current user taskbar alignment registry value to Left or Center. Explorer is not restarted. The visible result and current-build registry mapping still require verification on supported Windows 11 Home and Pro builds.

    .PARAMETER Alignment
    Specifies Left or Center.

    .EXAMPLE
    Set-WUTaskbarAlignment -Alignment Left

    Sets the current user taskbar alignment to the left.

    .INPUTS
    None

    .OUTPUTS
    None
    #>
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute(
        'PSShouldProcess',
        '',
        Justification = 'Registry property commands evaluate ShouldProcess for the delegated change.'
    )]
    [CmdletBinding(SupportsShouldProcess = $true)]
    param(
        [Parameter(Mandatory = $true, Position = 0)]
        [ValidateSet('Left', 'Center')]
        [string]$Alignment
    )

    $parameters = @{
        Name = 'TaskbarAlignment'
        Option = $Alignment
    }
    $parameters += Select-WUBoundParameter `
        -BoundParameters $PSBoundParameters `
        -Name 'WhatIf', 'Confirm'
    Set-WURegistrySetting @parameters
}
