function Enable-WUFileHistory {
    <#
    .SYNOPSIS
    Enables File History.

    .DESCRIPTION
    Applies the Enable option for File History. Registry changes are delegated to the registry property commands.

    .EXAMPLE
    Enable-WUFileHistory

    Enables File History.

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
        -Name 'FileHistory' `
        -Option 'Enable' `
        @shouldProcessParameters
}
