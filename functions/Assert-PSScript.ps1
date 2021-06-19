function Assert-WUPSScript {
    <#
        .SYNOPSIS
        Test the syntax and file extensions of powershell scripts. If it is not a valid script, write an error and return `$false`.

        .DESCRIPTION
        Returns a boolean value indicating whether the syntax and file extensions of PowerShell scripts are valid. If it is not a valid script, write an error and return `$false`.

        .OUTPUTS
        System.Boolean
        Returns a boolean value indicating whether the syntax and file extensions of PowerShell scripts are valid.

        .EXAMPLE
        PS C:\>Test-WUPSScript -LiteralPath 'PATH_TO_PSSCRIPT' -AllowedExtension '.ps1'

        This example returns `$true` if the file extension is `.ps1` and has a valid syntax, otherwise it writes an error and returns `$false`.

        .EXAMPLE
        PS C:\>Test-WUPSScript -Command '{"'

        This example writes an error and returns `$false`.

        .EXAMPLE
        PS C:\>(New-Object System.Net.WebClient).DownloadString('https://raw.githubusercontent.com/yuusakuri/PSWinUtil/master/functions/Find-Path.ps1') | Test-WUPSScript

        This example returns `$true`.

        .LINK
        Test-WUPSScript
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
        $AllowedExtension = ('.ps1', '.psm1', '.psd1')
    )

    begin {
        $isValidScriptArray = @()

        $removeParamKeys = @(
            'Path'
            'LiteralPath'
        )
        $paramsOfTestWUPSScript = @{ Assert = $true } + $PSBoundParameters
        @() + $paramsOfTestWUPSScript.Keys | `
            Where-Object { $_ -in $removeParamKeys } | `
            ForEach-Object { $paramsOfTestWUPSScript.Remove($_) }
    }
    process {
        if ($psCmdlet.ParameterSetName -eq 'Path') {
            foreach ($aPath in $Path) {
                $isValidScriptArray += Test-WUPSScript -Path $aPath @paramsOfTestWUPSScript
            }
        }
        elseif ($psCmdlet.ParameterSetName -eq 'LiteralPath') {
            foreach ($aPath in $LiteralPath) {
                $isValidScriptArray += Test-WUPSScript -LiteralPath $aPath @paramsOfTestWUPSScript
            }
        }
        else {
            $isValidScriptArray += Test-WUPSScript @paramsOfTestWUPSScript
        }
    }
    end {
        return $isValidScriptArray
    }
}
