function Set-WUNodeExtraCaCertificate {
    <#
    .SYNOPSIS
    Configures an additional CA certificate for Node.js.

    .DESCRIPTION
    Sets NODE_EXTRA_CA_CERTS to a fully qualified certificate bundle file path. Node.js and npm processes started after the environment variable is updated use the additional CA certificates. The file must already exist and contain one or more trusted certificates in PEM format.

    .PARAMETER CertificatePath
    Specifies a PEM file containing one or more additional trusted CA certificates.

    .PARAMETER Scope
    Specifies Process, User, or Machine. The default value is User. Machine changes do not start an elevated process.

    .EXAMPLE
    Set-WUNodeExtraCaCertificate -CertificatePath 'C:\Certificates\AdditionalRootCA.pem'

    Configures the specified CA certificate file for Node.js and npm.

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
        [Parameter(Mandatory = $true, Position = 0)]
        [ValidateNotNullOrEmpty()]
        [string]$CertificatePath,

        [Parameter()]
        [ValidateSet('Process', 'User', 'Machine')]
        [string]$Scope = 'User'
    )

    $resolvedCertificatePath = ConvertTo-WUFullPath -Path $CertificatePath
    if (-not (Test-Path -LiteralPath $resolvedCertificatePath -PathType Leaf)) {
        throw "The Node.js CA certificate file was not found: $resolvedCertificatePath"
    }

    $shouldProcessParameters = Select-WUBoundParameter `
        -BoundParameters $PSBoundParameters `
        -Name 'WhatIf', 'Confirm'

    Set-WUEnvironmentVariable `
        -Name 'NODE_EXTRA_CA_CERTS' `
        -Value $resolvedCertificatePath `
        -Scope $Scope `
        @shouldProcessParameters
}
