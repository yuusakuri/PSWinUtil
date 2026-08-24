function Set-WUAdvertisingIdMode {
    <#
    .SYNOPSIS
    Sets the advertising ID mode.

    .DESCRIPTION
    Applies the Default or Disabled option for the Windows advertising ID policy. Registry changes are delegated to the registry property commands.

    .PARAMETER Mode
    Specifies Default or Disabled.

    .EXAMPLE
    Set-WUAdvertisingIdMode -Mode Disabled

    Disables the advertising ID through Windows policy.

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
        [ValidateSet('Default', 'Disabled')]
        [string]$Mode
    )

    $shouldProcessParameters = Select-WUBoundParameter `
        -BoundParameters $PSBoundParameters `
        -Name 'WhatIf', 'Confirm'

    Set-WURegistrySetting `
        -Name 'AdvertisingId' `
        -Option $Mode `
        @shouldProcessParameters
}
