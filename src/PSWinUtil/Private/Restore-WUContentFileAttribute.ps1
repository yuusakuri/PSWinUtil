function Restore-WUContentFileAttribute {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [System.Collections.IDictionary]$ReadOnlyPaths
    )

    foreach ($filePath in $ReadOnlyPaths.Keys) {
        $attributes = [System.IO.File]::GetAttributes($filePath)
        [System.IO.File]::SetAttributes($filePath, ($attributes -bor [System.IO.FileAttributes]::ReadOnly))
    }
}
