function Get-WUMediaProperty {
    <#
        .SYNOPSIS
        Get properties about media files such as video files, audio files, and image files.

        .DESCRIPTION
        Get properties from multimedia streams. The properties that can be obtained includes duration, bit rate, codec, frame rate, width, height, etc.
    #>

    [CmdletBinding(DefaultParameterSetName = 'Path')]
    param (
        # Specifies a path to one or more locations. Wildcards are permitted.
        [Parameter(Mandatory,
            Position = 0,
            ParameterSetName = 'Path',
            ValueFromPipeline,
            ValueFromPipelineByPropertyName)]
        [ValidateNotNullOrEmpty()]
        [SupportsWildcards()]
        [string[]]
        $Path,

        # Specifies a path to one or more locations. Unlike the Path parameter, the value of the LiteralPath parameter is used exactly as it is typed. No characters are interpreted as wildcards. If the path includes escape characters, enclose it in single quotation marks. Single quotation marks tell Windows PowerShell not to interpret any characters as escape sequences.
        [Parameter(Mandatory,
            Position = 0,
            ParameterSetName = 'LiteralPath',
            ValueFromPipelineByPropertyName)]
        [Alias('PSPath')]
        [ValidateNotNullOrEmpty()]
        [string[]]
        $LiteralPath
    )

    begin {
        Set-StrictMode -Version 'Latest'

        $paths = @()
    }

    process {
        if ($psCmdlet.ParameterSetName -eq 'Path') {
            foreach ($aPath in $Path) {
                if (!(Assert-WUPathProperty -Path $aPath -PSProvider FileSystem -PSProvider FileSystem -PathType Leaf)) {
                    continue
                }

                $provider = $null
                $paths += $psCmdlet.SessionState.Path.GetResolvedProviderPathFromPSPath($aPath, [ref]$provider)
            }
        }
        else {
            foreach ($aPath in $LiteralPath) {
                if (!(Assert-WUPathProperty -LiteralPath $aPath -PSProvider FileSystem -PSProvider FileSystem -PathType Leaf)) {
                    continue
                }

                $paths += $psCmdlet.SessionState.Path.GetUnresolvedProviderPathFromPSPath($aPath)
            }
        }
    }

    end {
        $mediaProperties = @()

        foreach ($aPath in $paths) {
            $mediaJsonStr = $null
            $mediaJsonStr = ffprobe.exe -v quiet -print_format json -show_format -show_streams $aPath

            $isSucceeded = $null -ne $mediaJsonStr -and `
                $mediaJsonStr.PSobject.Properties.name -contains "Count" -and `
                $mediaJsonStr.Count -ne 3
            if (!$isSucceeded) {
                Write-Error "Cannot get media information for file '$aPath'."
                continue
            }

            $mediaProperties += $mediaJsonStr | ConvertFrom-Json
        }

        return $mediaProperties
    }
}
