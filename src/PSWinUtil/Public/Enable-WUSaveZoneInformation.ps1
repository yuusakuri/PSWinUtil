function Enable-WUSaveZoneInformation {
    <#
    .SYNOPSIS
    Enables download zone information.

    .DESCRIPTION
    Applies the Enable option for download zone information. Registry changes are delegated to the registry property commands.

    .EXAMPLE
    Enable-WUSaveZoneInformation

    Enables download zone information.

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
        -Name 'SaveZoneInformation' `
        -Option 'Enable' `
        @shouldProcessParameters
}
