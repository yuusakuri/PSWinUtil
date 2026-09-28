function Initialize-WUContentFileForAppend {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [System.Collections.IDictionary]$BoundParameter,

        [Parameter(Mandatory = $true)]
        [System.Collections.IDictionary]$OriginalAttributesByPath,

        [Parameter(Mandatory = $true)]
        [System.Collections.IDictionary]$PreparedFilePaths
    )

    foreach ($filePath in @(Get-WUContentFilePath -BoundParameter $BoundParameter)) {
        if ($PreparedFilePaths.Contains($filePath)) {
            continue
        }

        $attributes = [System.IO.File]::GetAttributes($filePath)
        $OriginalAttributesByPath[$filePath] = $attributes
        $PreparedFilePaths[$filePath] = $true
        if ($BoundParameter.Force) {
            $writableAttributes = $attributes -band (-bnot [System.IO.FileAttributes]::ReadOnly)
            [System.IO.File]::SetAttributes($filePath, $writableAttributes)
        }
        Convert-WUTextFileToUtf8Lf -Path $filePath
    }
}
