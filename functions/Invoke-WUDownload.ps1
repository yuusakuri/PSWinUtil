<#
  .SYNOPSIS
  Download files at high speed using aria2.

  .DESCRIPTION
  Download files at high speed using aria2.

  .EXAMPLE
  PS C:\>Invoke-WUDownload -URI "https://wslstorestorage.blob.core.windows.net/wslblob/wsl_update_x64.msi" -Destination $env:TMP -MaxConnectionPerServer 16 -Force

  This example downloads the file from the specified URI to $env:TMP. The maximum number of connections to one server is 16. Overwrites the destination file if it already exists.
#>

[CmdletBinding(
  SupportsShouldProcess,
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
  $URI,

  # Specifies the path to the location where the items are being moved. The default is the current directory.
  [ValidateNotNullOrEmpty()]
  [string]
  $Destination = $PWD.Path,

  # Specify the maximum number of connections to one server. The range of numbers is 1 to 16.
  [ValidateRange(1, 16)]
  [int]
  $MaxConnectionPerServer = 1,

  # Specify when overwriting the file.
  [switch]
  $Force
)

$Destination = $psCmdlet.SessionState.Path.GetUnresolvedProviderPathFromPSPath($Destination)

if ((Test-Path -LiteralPath $Destination -PathType Container)) {
  $outDir = $Destination
  $outName = ''
}
else {
  $outDir = Split-Path $Destination -Parent
  $outName = Split-Path $Destination -Leaf
}

if ($pscmdlet.ShouldProcess($URI, 'Download')) {
  Write-Host "Downloading from '$URI'"
  $ariaCmd = '& aria2c --auto-file-renaming=false -x {0} -d "{1}"' -f $MaxConnectionPerServer, $outDir
  if ($outName) {
    $ariaCmd = '{0} -o "{1}"' -f $ariaCmd, $outName
  }
  if ($Force) {
    $ariaCmd = '{0} --allow-overwrite=true' -f $ariaCmd
  }
  $ariaCmd = '{0} "{1}"' -f $ariaCmd, $URI

  Invoke-Expression $ariaCmd
}
