function ConvertTo-WUNuspec {
    <#
        .SYNOPSIS
        Extracts the nuspec file from the nupkg file, converts the contents to an XML object and returns it.

        .DESCRIPTION
        The extracted nuspec file will be placed in the same directory as the nupkg file.

        .INPUTS
        None

        .OUTPUTS
        System.Xml
        Returns nuspec xml object.

        .EXAMPLE
        PS C:\>ConvertTo-WUNuspec -NupkgPath 'test.nupkg'

        Extracts the nuspec file in 'test.nupkg' and returns the xml object.
    #>

    [CmdletBinding(SupportsShouldProcess)]
    param (
        # Specifies '*.nupkg' path to one locations. This parameter is used exactly as it is typed. No characters are interpreted as wildcards. If the path includes escape characters, enclose it in single quotation marks. Single quotation marks tell Windows PowerShell not to interpret any characters as escape sequences.
        [Parameter(Mandatory,
            Position = 0,
            ValueFromPipeline,
            ValueFromPipelineByPropertyName)]
        [Alias('LiteralPath', 'PSPath')]
        [ValidateNotNullOrEmpty()]
        [string]
        $NupkgPath
    )

    if (!(Assert-WUPathProperty -LiteralPath $NupkgPath -PSProvider FileSystem -PathType Leaf -Extension '.nupkg')) {
        return
    }

    $NupkgPath = $psCmdlet.SessionState.Path.GetUnresolvedProviderPathFromPSPath($NupkgPath)
    $nuspecPath = ($NupkgPath -replace '\.[\d.]*.nupkg$', '.nuspec')

    if (!(Test-WUPathProperty -LiteralPath $nuspecPath -PSProvider FileSystem -PathType Leaf)) {
        Write-Verbose "Cannot find nuspec file path '$nuspecPath'."

        try {
            $zip = [IO.Compression.ZipFile]::OpenRead($NupkgPath)
            $zip.Entries | Where-Object { $_.Name -like '*.nuspec' } | ForEach-Object { [System.IO.Compression.ZipFileExtensions]::ExtractToFile($_, $nuspecPath, $true) }
            $zip.Dispose()
        }
        catch {
            Write-Error "Failed to extract nuspec file '$nuspecPath' from nupkg file '$NupkgPath'."
            return
        }
    }

    Write-Verbose "Read xml from nuspec file '$nuspecPath'."

    return [xml](Get-Content -LiteralPath $nuspecPath)
}
