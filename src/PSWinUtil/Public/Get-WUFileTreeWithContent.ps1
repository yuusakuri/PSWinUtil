function Get-WUFileTreeWithContent {
    <#
    .SYNOPSIS
    Gets a file tree with text file contents.

    .DESCRIPTION
    Gets files and directories from one or more paths. Path permits wildcards, while LiteralPath uses exact paths. Directory children are read recursively. By default, each item is returned as a PSWinUtil.FileTreeContent object. Text files are read with strict UTF-8 decoding. A file that is not valid UTF-8 or contains a null character is returned with a null Content value.

    When AsXml is specified, the command writes a documents start element, one escaped document element for each item, and a documents end element. Each XML fragment is a separate pipeline value. A directory symbolic link or junction is returned but is not traversed.

    .PARAMETER Path
    Specifies one or more file system paths. Wildcards are supported.

    .PARAMETER LiteralPath
    Specifies one or more literal file system paths. Wildcards are not supported. The default value is the current location.

    .PARAMETER MinDepth
    Specifies the minimum directory depth to return. The input directory is depth 0 and its direct children are depth 1. The default value is 1. This parameter does not exclude a directly specified file.

    .PARAMETER MaxDepth
    Specifies the maximum directory depth to return. A value of 0 applies no maximum depth. The default value is 0. This parameter does not exclude a directly specified file.

    .PARAMETER AsXml
    Writes escaped XML fragments instead of PSWinUtil.FileTreeContent objects.

    .EXAMPLE
    Get-WUFileTreeWithContent

    Gets the items under the current location.

    .EXAMPLE
    Get-WUFileTreeWithContent -LiteralPath 'C:\MyProject\src' -MaxDepth 3

    Gets objects for items from depth 1 through depth 3.

    .EXAMPLE
    Get-WUFileTreeWithContent -LiteralPath 'C:\MyProject\src' -MinDepth 0 -MaxDepth 3 -AsXml

    Gets the input directory and its descendants as XML fragments.

    .EXAMPLE
    Get-WUFileTreeWithContent -Path 'C:\MyProject\src\*.ps1'

    Gets each PowerShell script selected by the wildcard path.

    .INPUTS
    System.String

    .OUTPUTS
    PSWinUtil.FileTreeContent
    System.String
    #>
    [CmdletBinding(DefaultParameterSetName = 'LiteralPath')]
    [OutputType('PSWinUtil.FileTreeContent')]
    [OutputType([string])]
    param(
        [Parameter(
            Mandatory = $true,
            ParameterSetName = 'Path',
            Position = 0,
            ValueFromPipeline = $true,
            ValueFromPipelineByPropertyName = $true
        )]
        [ValidateNotNullOrEmpty()]
        [SupportsWildcards()]
        [string[]]$Path,

        [Parameter(
            ParameterSetName = 'LiteralPath',
            Position = 0,
            ValueFromPipeline = $true,
            ValueFromPipelineByPropertyName = $true
        )]
        [Alias('PSPath', 'LP')]
        [ValidateNotNullOrEmpty()]
        [string[]]$LiteralPath = (Get-Location).Path,

        [Parameter()]
        [ValidateRange(0, [int]::MaxValue)]
        [int]$MinDepth = 1,

        [Parameter()]
        [ValidateRange(0, [int]::MaxValue)]
        [int]$MaxDepth = 0,

        [Parameter()]
        [switch]$AsXml
    )

    begin {
        if ($MaxDepth -gt 0 -and $MinDepth -gt $MaxDepth) {
            throw 'MinDepth cannot be greater than MaxDepth.'
        }

        $utf8 = [System.Text.UTF8Encoding]::new($false, $true)
        $writeItem = {
            param(
                [Parameter(Mandatory = $true)]
                [System.IO.FileSystemInfo]$Item
            )

            $isDirectory = $Item -is [System.IO.DirectoryInfo]
            $content = $null
            if (-not $isDirectory) {
                try {
                    $candidateContent = [System.IO.File]::ReadAllText($Item.FullName, $utf8)
                    if ($candidateContent.IndexOf([char]0) -lt 0) {
                        $content = $candidateContent
                    }
                } catch [System.Text.DecoderFallbackException] {
                    $content = $null
                }
            }

            if (-not $AsXml) {
                [pscustomobject]@{
                    PSTypeName = 'PSWinUtil.FileTreeContent'
                    Path = $Item.FullName
                    ItemType = if ($isDirectory) { 'Directory' } else { 'File' }
                    Content = $content
                }
                return
            }

            $null = [System.Xml.XmlConvert]::VerifyXmlChars($Item.FullName)
            $escapedPath = [System.Security.SecurityElement]::Escape($Item.FullName)
            if ($isDirectory) {
                '<document path="{0}" type="directory" />' -f $escapedPath
                return
            }
            if ($null -eq $content) {
                '<document path="{0}" type="file" />' -f $escapedPath
                return
            }

            $null = [System.Xml.XmlConvert]::VerifyXmlChars($content)
            $escapedContent = [System.Security.SecurityElement]::Escape($content)
            '<document path="{0}" type="file">{1}</document>' -f $escapedPath, $escapedContent
        }

        if ($AsXml) {
            '<documents>'
        }
    }

    process {
        $pathParameters = Select-WUBoundParameter `
            -BoundParameters $PSBoundParameters `
            -Name 'Path', 'LiteralPath'
        if ($pathParameters.Count -eq 0) {
            $pathParameters.LiteralPath = $LiteralPath
        }
        foreach ($fullPath in @(Resolve-WUExistingFileSystemPath @pathParameters)) {
            if ([System.IO.File]::Exists($fullPath)) {
                & $writeItem -Item ([System.IO.FileInfo]::new($fullPath))
                continue
            }

            $stack = [System.Collections.Generic.Stack[object]]::new()
            $stack.Push([pscustomobject]@{
                    Item = [System.IO.DirectoryInfo]::new($fullPath)
                    Depth = 0
                })
            while ($stack.Count -gt 0) {
                $node = $stack.Pop()
                if ($node.Depth -ge $MinDepth) {
                    & $writeItem -Item $node.Item
                }

                $isDirectory = $node.Item -is [System.IO.DirectoryInfo]
                $isReparsePoint = ($node.Item.Attributes -band [System.IO.FileAttributes]::ReparsePoint) -ne 0
                $canReadChildren = $isDirectory -and -not $isReparsePoint
                if ($MaxDepth -gt 0 -and $node.Depth -ge $MaxDepth) {
                    $canReadChildren = $false
                }
                if (-not $canReadChildren) {
                    continue
                }

                $children = @(
                    $node.Item.EnumerateFileSystemInfos() |
                        Sort-Object -Property FullName -Descending
                )
                foreach ($child in $children) {
                    $stack.Push([pscustomobject]@{
                            Item = $child
                            Depth = $node.Depth + 1
                        })
                }
            }
        }
    }

    end {
        if ($AsXml) {
            '</documents>'
        }
    }
}
