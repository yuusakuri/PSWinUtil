function Set-WUWindowsUpdateNotificationLevel {
    <#
    .SYNOPSIS
    Sets the Windows Update notification level.

    .DESCRIPTION
    Applies the Default, RestartWarningsOnly, or None option for Windows Update notifications. Registry changes are delegated to the registry property commands.

    .PARAMETER Level
    Specifies Default, RestartWarningsOnly, or None.

    .EXAMPLE
    Set-WUWindowsUpdateNotificationLevel -Level RestartWarningsOnly

    Shows only Windows Update restart warnings.

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
    param(
        [Parameter(Mandatory = $true, Position = 0)]
        [ValidateSet('Default', 'RestartWarningsOnly', 'None')]
        [string]$Level
    )

    $shouldProcessParameters = @{}
    foreach ($parameterName in @('WhatIf', 'Confirm')) {
        if ($PSBoundParameters.ContainsKey($parameterName)) {
            $shouldProcessParameters[$parameterName] = $PSBoundParameters[$parameterName]
        }
    }

    Set-WURegistrySetting `
        -Name 'WindowsUpdateNotificationLevel' `
        -Option $Level `
        @shouldProcessParameters
}
