function Unregister-WUStartupEntry {
    <#
    .SYNOPSIS
    Unregisters a Windows startup entry.

    .DESCRIPTION
    Removes one startup entry from one or more selected Run registry keys. A missing entry produces no change. The command does not start an elevated process.

    .PARAMETER Name
    Specifies the startup entry name.

    .PARAMETER Scope
    Specifies one or more of User and Machine. The default value is User.

    .EXAMPLE
    Unregister-WUStartupEntry -Name 'ExampleApp' -Scope User

    Removes ExampleApp from the current user startup entries.

    .EXAMPLE
    Unregister-WUStartupEntry -Name 'ExampleApp' -Scope User, Machine

    Removes ExampleApp from the current user and local machine startup entries.

    .INPUTS
    None

    .OUTPUTS
    None
    #>
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute(
        'PSShouldProcess',
        '',
        Justification = 'Remove-WURegistryProperty evaluates ShouldProcess for the delegated change.'
    )]
    [CmdletBinding(SupportsShouldProcess = $true)]
    param(
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$Name,

        [Parameter()]
        [ValidateSet('User', 'Machine')]
        [string[]]$Scope = 'User'
    )

    $shouldProcessParameters = Select-WUBoundParameter `
        -BoundParameters $PSBoundParameters `
        -Name 'WhatIf', 'Confirm'

    foreach ($currentScope in @($Scope | Select-Object -Unique)) {
        $registryPath = switch ($currentScope) {
            'User' { 'Registry::HKEY_CURRENT_USER\Software\Microsoft\Windows\CurrentVersion\Run' }
            'Machine' { 'Registry::HKEY_LOCAL_MACHINE\Software\Microsoft\Windows\CurrentVersion\Run' }
        }
        Remove-WURegistryProperty `
            -Path $registryPath `
            -Name $Name `
            @shouldProcessParameters
    }
}
