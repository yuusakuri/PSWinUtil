function Set-WUJavaExtraCaCertificate {
    <#
    .SYNOPSIS
    Imports an additional CA certificate into JAVA_HOME's trust store and configures JAVA_TOOL_OPTIONS.

    .DESCRIPTION
    Imports the specified CRT certificate into the cacerts file under JAVA_HOME and sets JAVA_TOOL_OPTIONS in the selected scopes to use that trust store. JAVA_HOME must identify the Java installation used by the Java applications.

    The Windows root certificate store is not recommended for Android Studio because Android Studio may use its bundled Java runtime instead of JAVA_HOME.

    .PARAMETER LiteralPath
    Specifies the additional CA certificate file in CRT format.

    .PARAMETER Scope
    Specifies one or more of Process, User, and Machine. The default is User.

    .EXAMPLE
    Set-WUJavaExtraCaCertificate -LiteralPath "$env:USERPROFILE\.certs\extra-ca-certs.crt"

    Imports the certificate into JAVA_HOME's cacerts and configures JAVA_TOOL_OPTIONS for the current user.

    .INPUTS
    None

    .OUTPUTS
    None
    #>
    [CmdletBinding(SupportsShouldProcess = $true)]
    param(
        [Parameter(Mandatory = $true, Position = 0)]
        [Alias('Path', 'PSPath', 'LP')]
        [ValidateNotNullOrEmpty()]
        [string]$LiteralPath,

        [Parameter()]
        [ValidateSet('Process', 'User', 'Machine')]
        [string[]]$Scope = 'User'
    )

    $extraCertificatePath = ConvertTo-WUFullPath -Path $LiteralPath
    $cacertsPath = Join-Path -Path $env:JAVA_HOME -ChildPath 'lib\security\cacerts'
    Assert-WUCommand -Name 'keytool'

    if ($PSCmdlet.ShouldProcess($cacertsPath, 'Import the additional CA certificate')) {
        $keytoolArguments = @(
            '-import'
            '-trustcacerts'
            '-keystore'
            $cacertsPath
            '-storepass'
            'changeit'
            '-noprompt'
            '-alias'
            'extra_cert'
            '-file'
            $extraCertificatePath
        )
        Invoke-WUNativeCommand -Command 'keytool' -ArgumentList $keytoolArguments -CaptureOutput -ErrorAction Stop | Out-Null
    }

    Set-WUEnvironmentVariable `
        -Name 'JAVA_TOOL_OPTIONS' `
        -Value "-Djavax.net.ssl.trustStore=$cacertsPath" `
        -Scope $Scope
}
