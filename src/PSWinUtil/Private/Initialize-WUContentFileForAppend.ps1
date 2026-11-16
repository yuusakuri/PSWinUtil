function Initialize-WUContentFileForAppend {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [System.Collections.IDictionary]$BoundParameter,

        [Parameter(Mandatory = $true)]
        [System.Collections.IDictionary]$ReadOnlyPaths,

        [Parameter(Mandatory = $true)]
        [System.Collections.IDictionary]$PreparedFilePaths
    )

    foreach ($filePath in @(Get-WUContentFilePath -BoundParameter $BoundParameter)) {
        if ($PreparedFilePaths.Contains($filePath)) {
            continue
        }

        $attributes = [System.IO.File]::GetAttributes($filePath)
        $PreparedFilePaths[$filePath] = $true
        $isReadOnly = ($attributes -band [System.IO.FileAttributes]::ReadOnly) -ne 0
        if ($BoundParameter.Force -and $isReadOnly) {
            $ReadOnlyPaths[$filePath] = $true
            $writableAttributes = $attributes -band (-bnot [System.IO.FileAttributes]::ReadOnly)
            [System.IO.File]::SetAttributes($filePath, $writableAttributes)
        }
        Convert-WUTextFileToUtf8Lf -Path $filePath
    }
}
