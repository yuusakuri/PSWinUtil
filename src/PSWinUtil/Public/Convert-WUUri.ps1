function Convert-WUUri {
    <#
    .SYNOPSIS
    Converts a URI by removing selected components.

    .DESCRIPTION
    Uses System.UriBuilder to create a new URI without the selected query or fragment. The input URI is not changed.

    .PARAMETER Uri
    Specifies one or more absolute URIs to convert.

    .PARAMETER WithoutQuery
    Removes the query component.

    .PARAMETER WithoutFragment
    Removes the fragment component.

    .EXAMPLE
    Convert-WUUri -Uri 'https://example.test/items?q=one#top' -WithoutQuery

    Returns a URI without the query and keeps the fragment.

    .EXAMPLE
    Convert-WUUri -Uri 'https://example.test/items'

    Reports an error because no conversion was selected.

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
        [uri[]]$Uri,

        [Parameter()]
        [switch]$WithoutQuery,

        [Parameter()]
        [switch]$WithoutFragment
    )

    begin {
        if (-not $WithoutQuery -and -not $WithoutFragment) {
            throw 'WithoutQuery or WithoutFragment must be specified.'
        }
    }

    process {
        foreach ($inputUri in $Uri) {
            if (-not $inputUri.IsAbsoluteUri) {
                throw "Uri must be absolute: $inputUri"
            }

            $builder = [System.UriBuilder]::new($inputUri)
            if ($WithoutQuery) {
                $builder.Query = [string]::Empty
            }
            if ($WithoutFragment) {
                $builder.Fragment = [string]::Empty
            }

            $builder.Uri
        }
    }
}
