function Disable-WUClassicContextMenu {
    <#
    .SYNOPSIS
    Disables the classic Windows 11 Explorer context menu.

    .DESCRIPTION
    Removes the default value created for the current user Explorer context menu compatibility key and preserves the key. Explorer is not restarted. Explorer must be restarted or the user must sign out before the result can appear. Current-build behavior still requires verification on supported Windows 11 Home and Pro builds.

    .EXAMPLE
    Disable-WUClassicContextMenu

    Restores the standard Explorer context menu configuration for the current user.

    .INPUTS
    None

    .OUTPUTS
    None
    #>
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute(
        'PSShouldProcess',
        '',
        Justification = 'Remove-WURegistryProperty evaluates ShouldProcess for the delegated change.'
    )]
    [CmdletBinding(SupportsShouldProcess = $true)]
    param()

    $parameters = @{
        Path = 'Registry::HKEY_CURRENT_USER\Software\Classes\CLSID\{86ca1aa0-34aa-4e8b-a509-50c905bae2a2}\InprocServer32'
        Name = ''
    }
    $parameters += Select-WUBoundParameter `
        -BoundParameters $PSBoundParameters `
        -Name 'WhatIf', 'Confirm'
    Remove-WURegistryProperty @parameters
}
