function Disable-WUWindowsHelloForBusiness {
    <#
    .SYNOPSIS
    Disables Windows Hello for Business.

    .DESCRIPTION
    Applies the Disable option for Windows Hello for Business. Registry changes are delegated to the registry property commands.

    .EXAMPLE
    Disable-WUWindowsHelloForBusiness

    Disables Windows Hello for Business.

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

    Set-WURegistrySetting `
        -Name 'WindowsHelloForBusiness' `
        -Option 'Disable' `
        @shouldProcessParameters
}
