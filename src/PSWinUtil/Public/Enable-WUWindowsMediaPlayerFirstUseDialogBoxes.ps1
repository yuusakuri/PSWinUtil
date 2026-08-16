function Enable-WUWindowsMediaPlayerFirstUseDialogBoxes {
    <#
    .SYNOPSIS
    Enables Windows Media Player first-use dialog boxes.

    .DESCRIPTION
    Applies the Enable option for Windows Media Player first-use dialog boxes. Registry changes are delegated to the registry property commands.

    .EXAMPLE
    Enable-WUWindowsMediaPlayerFirstUseDialogBoxes

    Enables Windows Media Player first-use dialog boxes.

    .INPUTS
    None

    .OUTPUTS
    None
    #>
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute(
        'PSUseSingularNouns',
        '',
        Justification = 'The public API uses the Windows setting name.'
    )]
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute(
        'PSShouldProcess',
        '',
        Justification = 'Registry property commands evaluate ShouldProcess for each delegated change.'
    )]
    [CmdletBinding(SupportsShouldProcess = $true)]
    param()

    $shouldProcessParameters = @{}
    foreach ($parameterName in @('WhatIf', 'Confirm')) {
        if ($PSBoundParameters.ContainsKey($parameterName)) {
            $shouldProcessParameters[$parameterName] = $PSBoundParameters[$parameterName]
        }
    }

    Set-WURegistrySettingOption `
        -Name 'WindowsMediaPlayerFirstUseDialogBoxes' `
        -Option 'Enable' `
        @shouldProcessParameters
}
