function Set-WUNativeCommandEncoding {
    <#
    .SYNOPSIS
    Sets native command input and output encoding to UTF-8.

    .DESCRIPTION
    Sets the current PowerShell process console input encoding, console output encoding, and native pipeline output encoding to UTF-8 without a byte order mark. File command encoding defaults are not changed.

    .EXAMPLE
    Set-WUNativeCommandEncoding

    Uses UTF-8 for standard input and output exchanged with native commands in the current PowerShell process.

    .INPUTS
    None

    .OUTPUTS
    None
    #>
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute(
        'PSAvoidGlobalVars',
        '',
        Justification = 'Windows PowerShell reads the native pipeline encoding from the global OutputEncoding variable.'
    )]
    [CmdletBinding(SupportsShouldProcess = $true)]
    param()

    if (-not $PSCmdlet.ShouldProcess('Current PowerShell process', 'Set native command encoding to UTF-8')) {
        return
    }

    $encoding = [System.Text.UTF8Encoding]::new($false)
    [Console]::InputEncoding = $encoding
    [Console]::OutputEncoding = $encoding
    $global:OutputEncoding = $encoding
}
