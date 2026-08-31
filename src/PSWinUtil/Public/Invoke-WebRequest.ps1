function Invoke-WebRequest {
    <#
    .SYNOPSIS
    Sends an HTTP or HTTPS request without rendering progress.

    .DESCRIPTION
    Proxies Microsoft.PowerShell.Utility Invoke-WebRequest with the Windows PowerShell 5.1 parameters. During the delegated request, progress rendering is suppressed to avoid its substantial Windows PowerShell performance cost. The caller's ProgressPreference value is restored after the request. The original cmdlet remains available as Microsoft.PowerShell.Utility\Invoke-WebRequest. PSWinUtil exports this function only in Windows PowerShell Desktop.

    .PARAMETER UseBasicParsing
    Uses the response content without Internet Explorer DOM parsing.

    .PARAMETER Uri
    Specifies the URI of the resource to request.

    .PARAMETER WebSession
    Specifies a web request session containing cookies and connection settings.

    .PARAMETER SessionVariable
    Stores the web request session in the named variable.

    .PARAMETER Credential
    Specifies credentials for the request.

    .PARAMETER UseDefaultCredentials
    Uses the credentials of the current user for the request.

    .PARAMETER CertificateThumbprint
    Specifies the client certificate by thumbprint.

    .PARAMETER Certificate
    Specifies a client certificate for the request.

    .PARAMETER UserAgent
    Specifies the user-agent string sent with the request.

    .PARAMETER DisableKeepAlive
    Disables persistent HTTP connections.

    .PARAMETER TimeoutSec
    Specifies the request timeout in seconds.

    .PARAMETER Headers
    Specifies HTTP headers sent with the request.

    .PARAMETER MaximumRedirection
    Specifies the maximum number of HTTP redirects to follow.

    .PARAMETER Method
    Specifies the HTTP method used for the request.

    .PARAMETER Proxy
    Specifies a proxy server for the request.

    .PARAMETER ProxyCredential
    Specifies credentials for the proxy server.

    .PARAMETER ProxyUseDefaultCredentials
    Uses the credentials of the current user for the proxy server.

    .PARAMETER Body
    Specifies the body of the request.

    .PARAMETER ContentType
    Specifies the content type of the request body.

    .PARAMETER TransferEncoding
    Specifies the transfer-encoding header value.

    .PARAMETER InFile
    Specifies a file whose content is sent as the request body.

    .PARAMETER OutFile
    Saves the response body to the specified file.

    .PARAMETER PassThru
    Returns a response object when OutFile is also specified.

    .EXAMPLE
    Invoke-WebRequest -Uri 'https://example.com/' -UseBasicParsing

    Gets a web resource without rendering request progress.

    .INPUTS
    System.Object

    .OUTPUTS
    Microsoft.PowerShell.Commands.HtmlWebResponseObject
    #>
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute(
        'PSAvoidOverwritingBuiltInCmdlets',
        '',
        Justification = 'The public proxy intentionally suppresses slow Windows PowerShell progress rendering.'
    )]
    [CmdletBinding(HelpUri = 'https://go.microsoft.com/fwlink/?LinkID=217035')]
    param(
        [Parameter()]
        [switch]$UseBasicParsing,

        [Parameter(Mandatory = $true, Position = 0)]
        [ValidateNotNullOrEmpty()]
        [uri]$Uri,

        [Parameter()]
        [Microsoft.PowerShell.Commands.WebRequestSession]$WebSession,

        [Parameter()]
        [Alias('SV')]
        [string]$SessionVariable,

        [Parameter()]
        [System.Management.Automation.CredentialAttribute()]
        [pscredential]$Credential,

        [Parameter()]
        [switch]$UseDefaultCredentials,

        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [string]$CertificateThumbprint,

        [Parameter()]
        [ValidateNotNull()]
        [System.Security.Cryptography.X509Certificates.X509Certificate]$Certificate,

        [Parameter()]
        [string]$UserAgent,

        [Parameter()]
        [switch]$DisableKeepAlive,

        [Parameter()]
        [ValidateRange(0, [int]::MaxValue)]
        [int]$TimeoutSec,

        [Parameter()]
        [System.Collections.IDictionary]$Headers,

        [Parameter()]
        [ValidateRange(0, [int]::MaxValue)]
        [int]$MaximumRedirection,

        [Parameter()]
        [Microsoft.PowerShell.Commands.WebRequestMethod]$Method,

        [Parameter()]
        [uri]$Proxy,

        [Parameter()]
        [System.Management.Automation.CredentialAttribute()]
        [pscredential]$ProxyCredential,

        [Parameter()]
        [switch]$ProxyUseDefaultCredentials,

        [Parameter(ValueFromPipeline = $true)]
        [object]$Body,

        [Parameter()]
        [string]$ContentType,

        [Parameter()]
        [ValidateSet('chunked', 'compress', 'deflate', 'gzip', 'identity')]
        [string]$TransferEncoding,

        [Parameter()]
        [string]$InFile,

        [Parameter()]
        [string]$OutFile,

        [Parameter()]
        [switch]$PassThru
    )

    begin {
        $originalProgressPreference = $ProgressPreference
        $ProgressPreference = 'SilentlyContinue'
        $steppablePipeline = $null
        try {
            $outBuffer = $null
            if ($PSBoundParameters.TryGetValue('OutBuffer', [ref]$outBuffer)) {
                $PSBoundParameters.OutBuffer = 1
            }

            $wrappedCommand = $ExecutionContext.InvokeCommand.GetCommand(
                'Microsoft.PowerShell.Utility\Invoke-WebRequest',
                [System.Management.Automation.CommandTypes]::Cmdlet
            )
            $commandScript = { & $wrappedCommand @PSBoundParameters }
            $steppablePipeline = $commandScript.GetSteppablePipeline($MyInvocation.CommandOrigin)
            $steppablePipeline.Begin($PSCmdlet)
        } catch {
            try {
                if ($null -ne $steppablePipeline) {
                    $steppablePipeline.Dispose()
                }
            } finally {
                $ProgressPreference = $originalProgressPreference
            }
            throw
        }
    }

    process {
        try {
            $steppablePipeline.Process($_)
        } catch {
            try {
                $steppablePipeline.Dispose()
            } finally {
                $ProgressPreference = $originalProgressPreference
            }
            throw
        }
    }

    end {
        try {
            $steppablePipeline.End()
        } finally {
            try {
                $steppablePipeline.Dispose()
            } finally {
                $ProgressPreference = $originalProgressPreference
            }
        }
    }
}
