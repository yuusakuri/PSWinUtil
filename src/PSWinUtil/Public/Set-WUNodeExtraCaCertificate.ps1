function Set-WUNodeExtraCaCertificate {
    <#
    .SYNOPSIS
    Configures an additional CA certificate for Node.js.

    .DESCRIPTION
    Sets NODE_EXTRA_CA_CERTS to a fully qualified certificate bundle file path. Node.js and npm processes started after the environment variable is updated use the additional CA certificates. The file must already exist and contain one or more trusted certificates in PEM format.

    .PARAMETER Path
    Specifies a PEM file containing one or more additional trusted CA certificates. Wildcards are supported when they resolve to exactly one file.

    .PARAMETER LiteralPath
    Specifies a PEM file containing one or more additional trusted CA certificates without wildcard interpretation.

    .PARAMETER Scope
    Specifies one or more of Process, User, and Machine. The default value is User. Machine changes do not start an elevated process.

    .EXAMPLE
    Set-WUNodeExtraCaCertificate -Path 'C:\Certificates\AdditionalRootCA.pem'

    Configures the specified CA certificate file for Node.js and npm.

    .EXAMPLE
    Set-WUNodeExtraCaCertificate -LiteralPath 'C:\Certificates\AdditionalRoot[1].pem' -Scope Process, User

    Configures the exact CA certificate file for the current process and current user environments.

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
    [CmdletBinding(
        DefaultParameterSetName = 'Path',
        SupportsShouldProcess = $true
    )]
    param(
        [Parameter(
            Mandatory = $true,
            ParameterSetName = 'Path',
            Position = 0
        )]
        [ValidateNotNullOrEmpty()]
        [SupportsWildcards()]
        [string]$Path,

        [Parameter(
            Mandatory = $true,
            ParameterSetName = 'LiteralPath'
        )]
        [Alias('PSPath', 'LP')]
        [ValidateNotNullOrEmpty()]
        [string]$LiteralPath,

        [Parameter()]
        [ValidateSet('Process', 'User', 'Machine')]
        [string[]]$Scope = 'User'
    )

    $resolveParameters = @{
        ParameterSetName = $PSCmdlet.ParameterSetName
        Path = $Path
        LiteralPath = $LiteralPath
        DenyMultiplePaths = $true
    }
    $fullCertificatePath = Resolve-WUPathFromParameterSet @resolveParameters |
        ConvertTo-WUFullPath
    Assert-WUPathProperty -LiteralPath $fullCertificatePath -Leaf

    $shouldProcessParameters = Select-WUBoundParameter -BoundParameters $PSBoundParameters -Name 'WhatIf', 'Confirm'

    Set-WUEnvironmentVariable -Name 'NODE_EXTRA_CA_CERTS' -Value $fullCertificatePath -Scope $Scope @shouldProcessParameters
}
