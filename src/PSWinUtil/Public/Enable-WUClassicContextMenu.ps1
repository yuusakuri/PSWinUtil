function Enable-WUClassicContextMenu {
    <#
    .SYNOPSIS
    Enables the classic Windows 11 Explorer context menu.

    .DESCRIPTION
    Sets the default value under the current user Explorer context menu compatibility key. Explorer is not restarted. Explorer must be restarted or the user must sign out before the result can appear. Current-build behavior still requires verification on supported Windows 11 Home and Pro builds.

    .EXAMPLE
    Enable-WUClassicContextMenu

    Configures the classic Explorer context menu for the current user.

    .INPUTS
    None

    .OUTPUTS
    None
    #>
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute(
        'PSShouldProcess',
        '',
        Justification = 'Set-WURegistryProperty evaluates ShouldProcess for the delegated change.'
    )]
    [CmdletBinding(SupportsShouldProcess = $true)]
    param()

    $parameters = @{
        Path = 'Registry::HKEY_CURRENT_USER\Software\Classes\CLSID\{86ca1aa0-34aa-4e8b-a509-50c905bae2a2}\InprocServer32'
        Name = ''
        Value = ''
        Type = 'String'
    }
    foreach ($parameterName in @('WhatIf', 'Confirm')) {
        if ($PSBoundParameters.ContainsKey($parameterName)) {
            $parameters[$parameterName] = $PSBoundParameters[$parameterName]
        }
    }
    Set-WURegistryProperty @parameters
}
