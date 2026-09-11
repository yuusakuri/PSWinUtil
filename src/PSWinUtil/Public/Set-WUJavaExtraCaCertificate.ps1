function Set-WUJavaExtraCaCertificate {
    <#
    .SYNOPSIS
    Copies a CA certificate into a Java trust store and configures JAVA_TOOL_OPTIONS to use it.

    .DESCRIPTION
    Copies the cacerts file from JAVA_HOME to the per-user .certs\java directory, imports the specified .crt certificate with keytool, and sets the User-scoped JAVA_TOOL_OPTIONS value to select that trust store. Java processes started after the environment variable is set use the additional certificate.

    The Windows root certificate store approach is not recommended for Android Studio because Android Studio may use its bundled Java runtime instead of JAVA_HOME. Configure the trust store used by the selected Java installation with this function.

    .PARAMETER LiteralPath
    Specifies the additional CA certificate file in CRT format.

    .PARAMETER JavaHome
    Specifies the Java installation that supplies the default cacerts file. The default is JAVA_HOME.

    .PARAMETER Scope
    Specifies one or more of Process, User, and Machine for JAVA_TOOL_OPTIONS. The default is User.

    .EXAMPLE
    Set-WUJavaExtraCaCertificate -LiteralPath "$env:USERPROFILE\.certs\extra-ca-certs.crt"

    Copies JAVA_HOME\lib\security\cacerts, imports the certificate, and configures JAVA_TOOL_OPTIONS for the current user.

    .EXAMPLE
    Set-WUJavaExtraCaCertificate -LiteralPath 'C:\Certificates\corporate-root.crt' -JavaHome 'C:\Program Files\Eclipse Adoptium\jdk-21'

    Uses the specified JDK trust store instead of JAVA_HOME.

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
        [ValidateNotNullOrEmpty()]
        [string]$JavaHome = $env:JAVA_HOME,

        [Parameter()]
        [ValidateSet('Process', 'User', 'Machine')]
        [string[]]$Scope = 'User'
    )

    if ([string]::IsNullOrWhiteSpace($JavaHome)) {
        throw 'JAVA_HOME must be set or JavaHome must be specified.'
    }
    $extraCertificatePath = ConvertTo-WUFullPath -Path $LiteralPath
    $defaultCacertsPath = Join-Path -Path $JavaHome -ChildPath 'lib\security\cacerts'
    $cacertsPath = Join-Path -Path $env:USERPROFILE -ChildPath '.certs\java\cacerts'

    Assert-WUPathProperty -LiteralPath $extraCertificatePath
    Assert-WUPathProperty -LiteralPath $defaultCacertsPath
    Assert-WUCommand -Name 'keytool'

    $target = "Java trust store '$cacertsPath'"
    if (-not $PSCmdlet.ShouldProcess($target, 'Copy cacerts, import the extra certificate, and set JAVA_TOOL_OPTIONS')) {
        return
    }

    New-Item -Path (Split-Path -Path $cacertsPath -Parent) -ItemType Directory -Force | Out-Null
    Copy-Item -LiteralPath $defaultCacertsPath -Destination $cacertsPath -Force | Out-Null

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
    $keytoolOutput = @(& 'keytool' @keytoolArguments 2>&1)
    $keytoolExitCode = $LASTEXITCODE
    if ($keytoolExitCode -ne 0) {
        $message = ($keytoolOutput | ForEach-Object { $_.ToString() }) -join [Environment]::NewLine
        throw "keytool failed with exit code $keytoolExitCode. $message"
    }

    Set-WUEnvironmentVariable `
        -Name 'JAVA_TOOL_OPTIONS' `
        -Value "-Djavax.net.ssl.trustStore=$cacertsPath" `
        -Scope $Scope
}
