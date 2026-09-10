function Write-WUFileTreeContentItem {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [System.IO.FileSystemInfo]$Item,

        [Parameter(Mandatory = $true)]
        [System.Text.UTF8Encoding]$Utf8,

        [Parameter()]
        [switch]$AsXml
    )

    $isDirectory = $Item -is [System.IO.DirectoryInfo]
    $content = $null
    if (-not $isDirectory) {
        try {
            $candidateContent = [System.IO.File]::ReadAllText($Item.FullName, $Utf8)
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

    [System.Xml.XmlConvert]::VerifyXmlChars($Item.FullName) | Out-Null
    $escapedPath = [System.Security.SecurityElement]::Escape($Item.FullName)
    if ($isDirectory) {
        '<document path="{0}" type="directory" />' -f $escapedPath
        return
    }
    if ($null -eq $content) {
        '<document path="{0}" type="file" />' -f $escapedPath
        return
    }

    [System.Xml.XmlConvert]::VerifyXmlChars($content) | Out-Null
    $escapedContent = [System.Security.SecurityElement]::Escape($content)
    '<document path="{0}" type="file">{1}</document>' -f $escapedPath, $escapedContent
}
