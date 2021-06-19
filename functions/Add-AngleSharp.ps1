function Add-WUAngleSharp {
    <#
        .SYNOPSIS
        Load AngleSharp DLL.

        .DESCRIPTION
        Load AngleSharp DLL.

        .LINK
        https://anglesharp.github.io/docs.html

        .LINK
        https://github.com/AngleSharp/AngleSharp
    #>

    [CmdletBinding()]
    param (
    )

    $typeExists = 'AngleSharp.Html.Parser.HtmlParser' -as [type]
    if (!$typeExists) {
        $assemblyPaths = Get-ChildItem -LiteralPath "$PSWinUtil\tools\AngleSharp" |
        ForEach-Object {
            $aTypeRootPath = $_.FullName
            Get-ChildItem -LiteralPath "$aTypeRootPath\lib" -File -Recurse |
            Where-Object { $_.Extension -eq '.dll' } |
            Where-Object { (Split-Path $_.FullName -Parent) -match 'netstandard[\d.]*' } |
            Select-Object -Last 1 -ExpandProperty FullName
        }

        if (!$assemblyPaths) {
            return
        }

        Add-Type -LiteralPath $assemblyPaths -ErrorAction SilentlyContinue
    }
}
