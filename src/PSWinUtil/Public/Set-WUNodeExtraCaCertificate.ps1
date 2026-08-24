function Set-WUNodeExtraCaCertificate {
    <#
    .SYNOPSIS
    Configures an additional CA certificate for Node.js.

    .DESCRIPTION
    Sets the current user's NODE_EXTRA_CA_CERTS environment variable to a fully qualified certificate file path. Node.js and npm processes started from subsequently opened sessions use the additional CA certificate. The certificate file must already exist.

    .PARAMETER CertificatePath
    Specifies the additional CA certificate file.

    .EXAMPLE
    Set-WUNodeExtraCaCertificate -CertificatePath 'C:\Certificates\AdditionalRootCA.crt'

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
        [string]$CertificatePath
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
        -Scope 'User' `
        @shouldProcessParameters
}
