function Enable-WUSmartScreenInShell {
    <#
    .SYNOPSIS
    Enables SmartScreen in the Windows shell.

    .DESCRIPTION
    Applies the Enable option for SmartScreen in the Windows shell. Registry changes are delegated to the registry property commands.

    .EXAMPLE
    Enable-WUSmartScreenInShell

    Enables SmartScreen in the Windows shell.

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
        -Option 'Enable' `
        @shouldProcessParameters
}
