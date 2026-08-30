function Enable-WUWebsiteAccessToLanguageList {
    <#
    .SYNOPSIS
    Enables website access to the language list.

    .DESCRIPTION
    Applies the Enable option for website access to the language list. Registry changes are delegated to the registry property commands.

    .EXAMPLE
    Enable-WUWebsiteAccessToLanguageList

    Enables website access to the language list.

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

    $shouldProcessParameters = Select-WUBoundParameter -BoundParameters $PSBoundParameters -Name 'WhatIf', 'Confirm'
    Set-WURegistrySetting -Name 'WebsiteAccessToLanguageList' -Option 'Enable' @shouldProcessParameters
}
