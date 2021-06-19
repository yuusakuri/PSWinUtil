function Invoke-WUDownload {
    <#
        .SYNOPSIS
        Download files at high speed using aria2.

        .DESCRIPTION
        Download files at high speed using aria2.

        .EXAMPLE
        PS C:\>Invoke-WUDownload -Uri "https://wslstorestorage.blob.core.windows.net/wslblob/wsl_update_x64.msi" -Destination $env:TMP -MaxConnectionPerServer 16 -Force

        This example downloads the file from the specified URI to $env:TMP. The maximum number of connections to one server is 16. Overwrites the destination file if it already exists.
    #>

    [CmdletBinding(SupportsShouldProcess,
        DefaultParameterSetName = 'Path')]
    param (
        # Specify the Uri of the file to download.
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

    $DestinationFullPath = ''
    $DestinationFullPath = $psCmdlet.SessionState.Path.GetUnresolvedProviderPathFromPSPath($Destination)
    if (!$DestinationFullPath) {
        return
    }

    if ((Test-Path -LiteralPath $DestinationFullPath -PathType Container)) {
        if (!(Assert-WUPathProperty -LiteralPath $DestinationFullPath -PSProvider FileSystem -PathType Container)) {
            return
        }
        $outDirPath = $DestinationFullPath
        $outName = ''
    }
    else {
        $outDirPath = Split-Path $DestinationFullPath -Parent
        $outName = Split-Path $DestinationFullPath -Leaf

        if (!$outDirPath) {
            Write-Error "Failed to get the parent directory of path '$DestinationFullPath'."
            return
        }

        if ((Test-Path -LiteralPath $outDirPath -PathType Container)) {
            if (!(Assert-WUPathProperty -LiteralPath $outDirPath -PSProvider FileSystem -PathType Container)) {
                return
            }
        }
        else {
            New-Item -Path $outDirPath -ItemType 'Directory' -Force | Out-String | Write-Verbose
            if (!(Assert-WUPathProperty -LiteralPath $outDirPath -PSProvider FileSystem -PathType Container)) {
                return
            }
        }
    }

    $cmd = '& aria2c --auto-file-renaming=false -x {0} ' -f $MaxConnectionPerServer
    $cmd = '{0} -d "{1}"' -f $cmd, (Convert-WUString -String $outDirPath -Type EscapeForPowerShellDoubleQuotation)
    if ($outName) {
        $cmd = '{0} -o "{1}"' -f $cmd, (Convert-WUString -String $outName -Type EscapeForPowerShellDoubleQuotation)
    }
    if ($Force) {
        $cmd = '{0} --allow-overwrite=true' -f $cmd
    }
    $cmd = '{0} "{1}"' -f $cmd, (Convert-WUString -String $Uri -Type EscapeForPowerShellDoubleQuotation)

    Write-Host "Downloading from '$Uri' to '$outDirPath'"
    if ($pscmdlet.ShouldProcess($cmd, 'Execute')) {
        Invoke-Expression $cmd
    }
}
