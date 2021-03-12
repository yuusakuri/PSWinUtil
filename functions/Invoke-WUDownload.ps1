<#
    .SYNOPSIS
    Download files at high speed using aria2.

    .DESCRIPTION
    Download files at high speed using aria2.

    .EXAMPLE
    PS C:\>Invoke-WUDownload -URI "https://wslstorestorage.blob.core.windows.net/wslblob/wsl_update_x64.msi" -Destination $env:TMP -MaxConnectionPerServer 16 -Force

    This example downloads the file from the specified URI to $env:TMP. The maximum number of connections to one server is 16. Overwrites the destination file if it already exists.
#>

[CmdletBinding(SupportsShouldProcess,
    DefaultParameterSetName = 'Path'
)]
param (
    #Specifies the Uniform Resource Identifier (URI) of the internet resource to which the web request is sent. Enter a URI.
    [Parameter(Mandatory,
        Position = 0,
        ValueFromPipeline,
        ValueFromPipelineByPropertyName)]
    [ValidateNotNullOrEmpty()]
    [uri]
    $Uri,

    # Specifies the path to the location where the items are being downloaded. The default is the current directory.
    [ValidateNotNullOrEmpty()]
    [string]
    $Destination = $PWD,

    # Specify the maximum number of connections to one server. The range of numbers is 1 to 16.
    [ValidateRange(1, 16)]
    [int]
    $MaxConnectionPerServer = 16,

    # Specify when overwriting the file.
    [switch]
    $Force
)

$DestinationFullPath = $psCmdlet.SessionState.Path.GetUnresolvedProviderPathFromPSPath($Destination)
if (!$DestinationFullPath) {
    return
}

if ((Test-Path -LiteralPath $DestinationFullPath -PathType Container)) {
    $outDirPath = $DestinationFullPath
    $outName = ''
}
else {
    $outDirPath = Split-Path $DestinationFullPath -Parent
    $outName = Split-Path $DestinationFullPath -Leaf

    if (!(Test-Path -LiteralPath $outDirPath -PathType Container)) {
        New-Item -Path $outDirPath -ItemType 'Directory' -Force | Out-String | Write-Verbose
        if (!(Test-Path -LiteralPath $outDirPath -PathType Container)) {
            return
        }
    }
}

$ariaCmd = '& aria2c --auto-file-renaming=false -x {0} -d "{1}"' -f $MaxConnectionPerServer, $outDirPath
if ($outName) {
    $ariaCmd = '{0} -o "{1}"' -f $ariaCmd, $outName
}
if ($Force) {
    $ariaCmd = '{0} --allow-overwrite=true' -f $ariaCmd
}
$ariaCmd = '{0} "{1}"' -f $ariaCmd, $URI

Write-Host "Downloading from '$URI' to '$outDirPath'"
if ($pscmdlet.ShouldProcess($ariaCmd, 'Execute')) {
    Invoke-Expression $ariaCmd
}
