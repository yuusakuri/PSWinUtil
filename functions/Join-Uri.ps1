function Join-WUUri {
    <#
        .SYNOPSIS
        Combines a uri and a child path into a single uri.

        .DESCRIPTION
        Combines a uri and a child path into a single uri.

        .OUTPUTS
        Uri
        This cmdlet returns the Combined uri.

        .EXAMPLE
        PS C:\>Join-WUUri -Uri 'https://www.google.com/?q=powershell' -ChildPath 'search'

        This example returns the Uri of `https://www.google.com/search?q=powershell`.
    #>

    [CmdletBinding()]
    param (
        # Specifies the main uri (or uris) to which the child-path is appended.
        [Parameter(Mandatory,
            Position = 0,
            ValueFromPipeline,
            ValueFromPipelineByPropertyName)]
        [ValidateNotNullOrEmpty()]
        [uri[]]
        $Uri,

        # Specifies the elements to append to the value of the Uri parameter.
        [Parameter(Mandatory,
            Position = 1,
            ValueFromPipelineByPropertyName)]
        [ValidateNotNullOrEmpty()]
        [string]
        $ChildPath
    )

    begin {
        Set-StrictMode -Version 'Latest'
    }

    process {
        foreach ($aUri in $Uri) {
            [uri]$uriWithoutQuery = Get-WUUriWithoutQuery -Uri $aUri
            if (!($uriWithoutQuery -match '/$')) {
                [uri]$uriWithoutQuery = '{0}/' -f $uriWithoutQuery
            }
            $ChildPath = $ChildPath -replace '^/'
            $query = $aUri.Query

            [uri]('{0}{1}' -f ([uri]::new($uriWithoutQuery, $ChildPath), $query))
        }
    }
}
