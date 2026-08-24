function Enable-WUJavaWindowsRootTrustStore {
    <#
    .SYNOPSIS
    Configures Java to use the Windows root certificate store.

    .DESCRIPTION
    Sets the current user's JAVA_TOOL_OPTIONS environment variable so Java processes use the Windows ROOT certificate store for TLS trust decisions. Java processes started from subsequently opened sessions receive the option.

    .EXAMPLE
    Enable-WUJavaWindowsRootTrustStore

    Configures Java to use the Windows ROOT certificate store for the current user.

    .INPUTS
    None

    .OUTPUTS
    None
    #>
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute(
        'PSShouldProcess',
        '',
        Justification = 'Set-WUEnvironmentVariable evaluates ShouldProcess for the delegated change.'
    )]
    [CmdletBinding(SupportsShouldProcess = $true)]
    param()

    $shouldProcessParameters = Select-WUBoundParameter `
        -BoundParameters $PSBoundParameters `
        -Name 'WhatIf', 'Confirm'

    Set-WUEnvironmentVariable `
        -Name 'JAVA_TOOL_OPTIONS' `
        -Value '-Djavax.net.ssl.trustStoreType=WINDOWS-ROOT' `
        -Scope 'User' `
        @shouldProcessParameters
}
