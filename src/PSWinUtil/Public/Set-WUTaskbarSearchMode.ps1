function Set-WUTaskbarSearchMode {
    <#
    .SYNOPSIS
    Sets the Windows 11 taskbar search mode.

    .DESCRIPTION
    Sets the current user taskbar search registry value to Hidden, Icon, or SearchBox. Explorer is not restarted. The visible result and current-build registry mapping still require verification on supported Windows 11 Home and Pro builds.

    .PARAMETER Mode
    Specifies Hidden, Icon, or SearchBox.

    .EXAMPLE
    Set-WUTaskbarSearchMode -Mode Icon

    Shows the taskbar search icon.

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
        [ValidateSet('Hidden', 'Icon', 'SearchBox')]
        [string]$Mode
    )

    $settingParameters = @{
        Name = 'TaskbarSearchMode'
        Option = $Mode
    }
    $settingParameters += Select-WUBoundParameter -BoundParameters $PSBoundParameters -Name 'WhatIf', 'Confirm'
    Set-WURegistrySetting @settingParameters
}
