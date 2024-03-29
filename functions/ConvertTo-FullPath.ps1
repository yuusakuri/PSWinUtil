﻿function ConvertTo-WUFullPath {
    <#
        .SYNOPSIS
        Converts a relative path to an absolute path.

        .DESCRIPTION
        The path does not have to exist. However, the base path specified for parameter `-BasePath` must exist. Also, It doesn't verify the validity of the path. The PSProviders of the paths must be filesystem or registry.

        .EXAMPLE
        PS C:\>ConvertTo-WUFullPath -Path 'power*ise.exe' -BasePath 'C:\Windows\System32\WindowsPowerShell\v1.0'

        Returns `C:\Windows\System32\WindowsPowerShell\v1.0\powershell_ise.exe`.

        .EXAMPLE
        PS C:\>ConvertTo-WUFullPath 'NON_EXISTENT_PATH' -BasePath '/'

        Returns `C:\NON_EXISTENT_PATH`.
    #>

    [CmdletBinding(
        SupportsShouldProcess,
        DefaultParameterSetName = 'Path')]
    param (
        # Specifies a path to one or more locations. Wildcards are permitted. The default location is the current directory (.).
        [Parameter(Position = 0,
            ParameterSetName = 'Path',
            ValueFromPipeline,
            ValueFromPipelineByPropertyName)]
        [ValidateNotNullOrEmpty()]
        [SupportsWildcards()]
        [string[]]
        $Path = $PWD,

        # Specifies a path to one or more locations. Unlike the Path parameter, the value of the LiteralPath parameter is used exactly as it is typed. No characters are interpreted as wildcards. If the path includes escape characters, enclose it in single quotation marks. Single quotation marks tell Windows PowerShell not to interpret any characters as escape sequences. The default location is the current directory (.).
        [Parameter(Position = 0,
            ParameterSetName = 'LiteralPath',
            ValueFromPipelineByPropertyName)]
        [Alias('PSPath')]
        [ValidateNotNullOrEmpty()]
        [string[]]
        $LiteralPath,

        # Specify key names of the registry. Converts specified key names to path.
        [Parameter(Position = 0,
            ParameterSetName = 'Keyname',
            ValueFromPipelineByPropertyName)]
        [ValidateNotNullOrEmpty()]
        [string[]]
        $Keyname,

        # Specify the beginning of a fully qualified path. The default location is the current directory (.).
        [Parameter(ParameterSetName = 'Path')]
        [Parameter(ParameterSetName = 'LiteralPath')]
        [ValidateNotNullOrEmpty()]
        [string]
        $BasePath = $PWD,

        # If specified, creates the base path specified for parameter `-BasePath` and the parent directory of the obtained path.
        [Parameter(ParameterSetName = 'Path')]
        [Parameter(ParameterSetName = 'LiteralPath')]
        [switch]
        $Parents,

        # Allows invalid path characters and syntax.
        [switch]
        $AllowInvalid
    )

    begin {
        Set-StrictMode -Version 'Latest'

        $paths = @()
        $shouldClose = $false

        if (!($PSCmdlet.ParameterSetName -eq 'Keyname')) {
            if (!(Test-Path -LiteralPath $BasePath -PathType Container)) {
                if ((Test-Path -LiteralPath $BasePath -PathType Leaf)) {
                    $shouldClose = $true
                    Write-Error "BasePath '$BasePath' is not a Directory."
                    return
                }

                if ($Parents) {
                    New-Item -Path $BasePath -ItemType 'Directory' -Force | Out-String | Write-Verbose
                }

                if (!(Assert-WUPathProperty -LiteralPath $BasePath -PSProvider FileSystem, Registry -PathType Container)) {
                    $shouldClose = $true
                    return
                }
            }

            Push-Location -LiteralPath $BasePath
        }
    }

    process {
        if ($shouldClose) {
            return
        }

        if ($PSCmdlet.ParameterSetName -eq 'Keyname') {
            foreach ($aKeyname in $Keyname) {
                if (!($aKeyname -match ':')) {
                    $aKeyname = "Registry::$aKeyname"
                }
                $paths += $aKeyname
            }
        }
        else {
            if ($PSCmdlet.ParameterSetName -eq 'Path') {
                foreach ($aPath in $Path) {
                    if ((Test-Path -Path $aPath)) {
                        # Resolve any wildcards that might be in the path
                        $provider = $null
                        $paths += $PSCmdlet.SessionState.Path.GetResolvedProviderPathFromPSPath($aPath, [ref]$provider)
                    }
                    else {
                        $paths += $PSCmdlet.SessionState.Path.GetUnresolvedProviderPathFromPSPath($aPath)
                    }
                }
            }
            else {
                foreach ($aPath in $LiteralPath) {
                    $paths += $PSCmdlet.SessionState.Path.GetUnresolvedProviderPathFromPSPath($aPath)
                }
            }
        }
    }

    end {
        Pop-Location

        if (!$paths -or $shouldClose) {
            return
        }

        if (!$AllowInvalid) {
            $invalidCharRegex = (
                [System.IO.Path]::GetInvalidPathChars() |
                ForEach-Object { [regex]::Escape($_) }
            ) -join '|'

            $paths = $paths | Where-Object {
                if ($_ -match $invalidCharRegex) {
                    Write-Error "Path '$_' contains invalid characters."
                    return $false
                }
                elseif (!(Test-Path -LiteralPath $_ -IsValid)) {
                    Write-Error "Path '$_' syntax is invalid."
                    return $false
                }
                else {
                    return $true
                }
            }
        }

        if ($Parents) {
            $parentPaths = @()
            $parentPaths += Split-Path $paths -Parent | Where-Object { $_ }

            foreach ($aParentPath in $parentPaths) {
                if (!(Test-Path -LiteralPath $aParentPath -PathType Container)) {
                    New-Item -Path $aParentPath -ItemType 'Directory' -Force | Out-String | Write-Verbose
                }
            }
        }

        return $paths
    }
}
