function Test-WUPSScript {
    <#
        .SYNOPSIS
        Test the syntax and file extensions of powershell scripts.

        .DESCRIPTION
        Returns a boolean value indicating whether the syntax and file extensions of PowerShell scripts are valid.

        .OUTPUTS
        System.Boolean
        Returns a boolean value indicating whether the syntax and file extensions of PowerShell scripts are valid.

        .EXAMPLE
        PS C:\>Test-WUPSScript -LiteralPath 'PATH_TO_PSSCRIPT' -AllowedExtension '.ps1'

        This example returns `$true` if the file extension is `.ps1` and has a valid syntax, otherwise it returns `$false`.

        .EXAMPLE
        PS C:\>(New-Object System.Net.WebClient).DownloadString('https://raw.githubusercontent.com/yuusakuri/PSWinUtil/master/functions/Find-Path.ps1') | Test-WUPSScript

        This example returns `$true`.

        .LINK
        Assert-WUPSScript
    #>

    [CmdletBinding(DefaultParameterSetName = 'Command')]
    param (
        # Specifies a path to one or more locations. Wildcards are permitted.
        [Parameter(Mandatory,
            Position = 0,
            ParameterSetName = 'Path',
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
        $LiteralPath,

        # Specifies command or expression.
        [Parameter(Mandatory,
            Position = 0,
            ParameterSetName = 'Command',
            ValueFromPipeline,
            ValueFromPipelineByPropertyName)]
        [ValidateNotNullOrEmpty()]
        [string]
        $Command,

        # Specifies the allowed extensions. This parameter can only be specified if the Powershell script path is specified.
        [Parameter(ParameterSetName = 'Path')]
        [Parameter(ParameterSetName = 'LiteralPath')]
        [ValidateSet('Any', '.ps1', '.psm1', '.psd1')]
        [string[]]
        $AllowedExtension = ('.ps1', '.psm1', '.psd1'),

        # Writes an error if the specified powershell script is not valid.
        [switch]
        $Assert
    )

    begin {
        Set-StrictMode -Version 'Latest'

        function Test-WUPSScriptSyntax {
            [CmdletBinding(DefaultParameterSetName = 'Command')]
            param(
                [Parameter(Mandatory,
                    Position = 0,
                    ParameterSetName = 'FilePath')]
                [string]
                $FilePath,

                [Parameter(Mandatory,
                    Position = 0,
                    ParameterSetName = 'Command')]
                [string]
                $Command,

                [switch]
                $Assert
            )

            $Errors = @()
            if ($PSCmdlet.ParameterSetName -eq 'Command') {
                [void][System.Management.Automation.Language.Parser]::ParseInput($Command, [ref]$null, [ref]$Errors)
            }
            else {
                [void][System.Management.Automation.Language.Parser]::ParseFile($FilePath, [ref]$null, [ref]$Errors)
            }

            if ($Assert -and $Errors.Count) {
                Write-Error "The powershell script is not a valid syntax."
            }

            return !$Errors.Count
        }

        $isValidScriptArray = @()
    }

    process {
        if ($psCmdlet.ParameterSetName -eq 'Path') {
            foreach ($aPath in $Path) {
                $fullPaths = @()
                $fullPaths += Resolve-Path -Path $aPath -ErrorAction Continue | Select-Object -ExpandProperty Path
                if (!$fullPaths) {
                    $isValidScriptArray += $false
                    continue
                }

                foreach ($aFullPath in $fullPaths) {
                    $isValidScriptArray += (Assert-WUPathProperty -LiteralPath $aFullPath -PathType Leaf -PSProvider FileSystem) `
                        -and (Test-WUPathProperty -LiteralPath $aFullPath -Extension $AllowedExtension -Assert:$Assert) `
                        -and (Test-WUPSScriptSyntax -FilePath $aFullPath -Assert:$Assert)
                }
            }
        }
        elseif ($psCmdlet.ParameterSetName -eq 'LiteralPath') {
            foreach ($aPath in $LiteralPath) {
                $fullPaths = @()
                $fullPaths += Resolve-Path -LiteralPath $aPath -ErrorAction Continue | Select-Object -ExpandProperty Path
                if (!$fullPaths) {
                    $isValidScriptArray += $false
                    continue
                }

                foreach ($aFullPath in $fullPaths) {
                    $isValidScriptArray += (Assert-WUPathProperty -LiteralPath $aFullPath -PathType Leaf -PSProvider FileSystem) `
                        -and (Test-WUPathProperty -LiteralPath $aFullPath -Extension $AllowedExtension -Assert:$Assert) `
                        -and (Test-WUPSScriptSyntax -FilePath $aFullPath -Assert:$Assert)
                }
            }
        }
        else {
            $isValidScriptArray += Test-WUPSScriptSyntax -Command $Command -Assert:$Assert
        }
    }

    end {
        return $isValidScriptArray
    }
}
