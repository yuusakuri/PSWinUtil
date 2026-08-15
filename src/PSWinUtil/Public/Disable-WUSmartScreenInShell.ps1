function Disable-WUSmartScreenInShell {
    <#
    .SYNOPSIS
    Disables SmartScreen in the Windows shell.

    .DESCRIPTION
    Applies the Disable option for SmartScreen in the Windows shell. Registry changes are delegated to the registry property commands.

    .EXAMPLE
    Disable-WUSmartScreenInShell

    Disables SmartScreen in the Windows shell.

    .INPUTS
    None

    .OUTPUTS
    None
    #>
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
        -Name 'SmartScreenInShell' `
        -Option 'Disable' `
        @shouldProcessParameters
}
