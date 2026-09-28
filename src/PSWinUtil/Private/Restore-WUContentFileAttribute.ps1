function Restore-WUContentFileAttribute {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [System.Collections.IDictionary]$OriginalAttributesByPath
    )

    foreach ($filePath in $OriginalAttributesByPath.Keys) {
        [System.IO.File]::SetAttributes($filePath, $OriginalAttributesByPath[$filePath])
    }
}
