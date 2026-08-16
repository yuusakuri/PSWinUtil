function Disable-WUWindowsMediaPlayerFirstUseDialogBoxes {
    <#
    .SYNOPSIS
    Disables Windows Media Player first-use dialog boxes.

    .DESCRIPTION
    Applies the Disable option for Windows Media Player first-use dialog boxes. Registry changes are delegated to the registry property commands.

    .EXAMPLE
    Disable-WUWindowsMediaPlayerFirstUseDialogBoxes

    Disables Windows Media Player first-use dialog boxes.

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
        -Option 'Disable' `
        @shouldProcessParameters
}
