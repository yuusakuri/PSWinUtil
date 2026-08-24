function Enable-WUJavaWindowsRootTrustStore {
    <#
    .SYNOPSIS
    Configures Java to use the Windows root certificate store.

    .DESCRIPTION
    Adds the Windows ROOT trust store option to JAVA_TOOL_OPTIONS without removing unrelated Java options. The option is applied to Java processes started after the environment variable is updated.

    .PARAMETER Scope
    Specifies Process, User, or Machine. The default value is User. Machine changes do not start an elevated process.

    .EXAMPLE
    Enable-WUJavaWindowsRootTrustStore

    Configures Java to use the Windows ROOT certificate store for the current user while preserving existing JAVA_TOOL_OPTIONS values.

    .EXAMPLE
    Enable-WUJavaWindowsRootTrustStore -Scope Process

    Configures Java processes started from the current PowerShell process to use the Windows ROOT certificate store.

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
    param(
        [Parameter()]
        [ValidateSet('Process', 'User', 'Machine')]
        [string]$Scope = 'User'
    )

    $javaToolOptions = Get-WUEnvironmentVariable `
        -Name 'JAVA_TOOL_OPTIONS' `
        -Scope $Scope

    $updatedJavaToolOptions = [string]$javaToolOptions
    $requiredOptions = @(
        @{
            Pattern = '(?<!\S)-Djavax\.net\.ssl\.trustStore=\S+'
            Value = '-Djavax.net.ssl.trustStore=NONE'
        }
        @{
            Pattern = '(?<!\S)-Djavax\.net\.ssl\.trustStoreType=\S+'
            Value = '-Djavax.net.ssl.trustStoreType=Windows-ROOT'
        }
    )
    foreach ($requiredOption in $requiredOptions) {
        if ([string]::IsNullOrWhiteSpace($updatedJavaToolOptions)) {
            $updatedJavaToolOptions = $requiredOption.Value
        } elseif ($updatedJavaToolOptions -match $requiredOption.Pattern) {
            $updatedJavaToolOptions = [regex]::Replace(
                $updatedJavaToolOptions,
                $requiredOption.Pattern,
                $requiredOption.Value
            )
        } else {
            $updatedJavaToolOptions = "$($updatedJavaToolOptions.Trim()) $($requiredOption.Value)"
        }
    }

    $shouldProcessParameters = Select-WUBoundParameter `
        -BoundParameters $PSBoundParameters `
        -Name 'WhatIf', 'Confirm'

    Set-WUEnvironmentVariable `
        -Name 'JAVA_TOOL_OPTIONS' `
        -Value $updatedJavaToolOptions `
        -Scope $Scope `
        @shouldProcessParameters
}
