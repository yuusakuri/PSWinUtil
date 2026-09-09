function Set-WUJavaWindowsRootTrustStore {
    <#
    .SYNOPSIS
    Configures Java to use the Windows root certificate store.

    .DESCRIPTION
    In corporate or otherwise restricted network environments, JAVA_TOOL_OPTIONS is often used to force Java SSL verification through the Windows system certificate store (WINDOWS-ROOT). Bundled JDKs installed with Android Studio or IntelliJ may omit, customize, or contain defects in support for this Windows-specific store, causing HTTPS downloads to fail.

    The robust solution is to point build tools at a standard JDK installed on the computer, such as Amazon Corretto or Oracle JDK, instead of modifying a bundled JDK. Configure that JDK through JAVA_HOME or the tool-specific JDK setting; this approach also applies to Flutter, Android development, and general Java development. This command configures the Windows ROOT trust store option for Java processes started after the environment variable is updated, while preserving unrelated Java options.

    .PARAMETER Scope
    Specifies one or more of Process, User, and Machine. The default value is User. Machine changes do not start an elevated process.

    .EXAMPLE
    Set-WUJavaWindowsRootTrustStore

    Configures Java to use the Windows ROOT certificate store for the current user while preserving existing JAVA_TOOL_OPTIONS values.

    .EXAMPLE
    Set-WUJavaWindowsRootTrustStore -Scope Process, User

    Configures Java processes started from the current PowerShell process and current user environment to use the Windows ROOT certificate store.

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
        [string[]]$Scope = 'User'
    )

    $shouldProcessParameters = Select-WUBoundParameter -BoundParameters $PSBoundParameters -Name 'WhatIf', 'Confirm'
    $optionValuePattern = '(?:"(?:[^"\\]|\\.)*"|''(?:[^''\\]|\\.)*''|\S+)'
    $trustStorePattern = "(?<!\S)-Djavax\.net\.ssl\.trustStore=$optionValuePattern(?:\s+|$)"
    $trustStoreTypePattern = "(?<!\S)-Djavax\.net\.ssl\.trustStoreType=$optionValuePattern(?:\s+|$)"
    $trustStoreTypeOption = '-Djavax.net.ssl.trustStoreType=Windows-ROOT'

    foreach ($targetScope in $Scope) {
        $javaToolOptions = Get-WUEnvironmentVariable -Name 'JAVA_TOOL_OPTIONS' -Scope $targetScope
        $updatedJavaToolOptions = [string]$javaToolOptions
        $updatedJavaToolOptions = [regex]::Replace(
            $updatedJavaToolOptions,
            $trustStorePattern,
            '',
            [System.Text.RegularExpressions.RegexOptions]::IgnoreCase
        )
        $updatedJavaToolOptions = [regex]::Replace(
            $updatedJavaToolOptions,
            $trustStoreTypePattern,
            '',
            [System.Text.RegularExpressions.RegexOptions]::IgnoreCase
        ).Trim()

        if ([string]::IsNullOrWhiteSpace($updatedJavaToolOptions)) {
            $updatedJavaToolOptions = $trustStoreTypeOption
        } else {
            $updatedJavaToolOptions = "$($updatedJavaToolOptions.Trim()) $trustStoreTypeOption"
        }

        Set-WUEnvironmentVariable -Name 'JAVA_TOOL_OPTIONS' -Value $updatedJavaToolOptions -Scope $targetScope @shouldProcessParameters
    }
}
