function Join-WUUri {
    <#
    .SYNOPSIS
    Resolves a relative URI against a base URI.

    .DESCRIPTION
    Uses System.Uri resolution to combine an absolute base URI and a relative URI. Slash handling and parent segments follow System.Uri behavior.

    .PARAMETER BaseUri
    Specifies one or more absolute base URIs.

    .PARAMETER RelativeUri
    Specifies the relative URI to resolve against each base URI.

    .EXAMPLE
    Join-WUUri -BaseUri 'https://example.test/api/' -RelativeUri '../status'

    Returns a System.Uri for https://example.test/status.

    .EXAMPLE
    Join-WUUri -BaseUri '/api/' -RelativeUri 'status'

    Reports an error because BaseUri is not absolute.

    .INPUTS
    System.Uri

    .OUTPUTS
    System.Uri
    #>
    [CmdletBinding()]
    [OutputType([uri])]
    param(
        [Parameter(
            Mandatory = $true,
            Position = 0,
            ValueFromPipeline = $true,
            ValueFromPipelineByPropertyName = $true
        )]
        [ValidateNotNull()]
        [uri[]]$BaseUri,

        [Parameter(Mandatory = $true, Position = 1)]
        [ValidateNotNullOrEmpty()]
        [string]$RelativeUri
    )

    process {
        foreach ($inputBaseUri in $BaseUri) {
            if (-not $inputBaseUri.IsAbsoluteUri) {
                throw "BaseUri must be absolute: $inputBaseUri"
            }

            [uri]::new($inputBaseUri, $RelativeUri)
        }
    }
}
