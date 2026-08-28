function Start-WUPSScriptAsAdmin {
    <#
    .SYNOPSIS
    Starts a PowerShell script as an administrator.

    .DESCRIPTION
    Validates a .ps1 file and starts it in a separate Windows PowerShell process by using Start-Process with the RunAs verb. Script arguments are encoded into the command so each string value is preserved.

    .PARAMETER Path
    Specifies the .ps1 file to start. Wildcards are supported when they resolve to exactly one file.

    .PARAMETER LiteralPath
    Specifies the .ps1 file to start without wildcard interpretation.

    .PARAMETER ArgumentList
    Specifies string arguments passed to the script in their original order.

    .EXAMPLE
    Start-WUPSScriptAsAdmin -Path '.\setup.ps1' -ArgumentList 'install', 'C:\Program Files\My App'

    Starts setup.ps1 in an elevated Windows PowerShell process.

    .EXAMPLE
    Start-WUPSScriptAsAdmin -Path '.\setup.ps1' -WhatIf

    Validates setup.ps1 and shows the elevated start operation without starting a process.

    .EXAMPLE
    Start-WUPSScriptAsAdmin -Path '.\setup.txt'

    Reports an error because the input file does not use the .ps1 extension.

    .EXAMPLE
    Start-WUPSScriptAsAdmin -LiteralPath '.\setup[local].ps1'

    Starts the exact script file in an elevated Windows PowerShell process.

    .INPUTS
    System.String

    .OUTPUTS
    None
    #>
    [CmdletBinding(
        DefaultParameterSetName = 'Path',
        SupportsShouldProcess = $true
    )]
    param(
        [Parameter(
            Mandatory = $true,
            ParameterSetName = 'Path',
            Position = 0,
            ValueFromPipeline = $true,
            ValueFromPipelineByPropertyName = $true
        )]
        [Alias('FullName')]
        [ValidateNotNullOrEmpty()]
        [SupportsWildcards()]
        [string]$Path,

        [Parameter(
            Mandatory = $true,
            ParameterSetName = 'LiteralPath',
            ValueFromPipelineByPropertyName = $true
        )]
        [Alias('PSPath', 'LP')]
        [ValidateNotNullOrEmpty()]
        [string]$LiteralPath,

        [Parameter()]
        [AllowEmptyCollection()]
        [AllowEmptyString()]
        [string[]]$ArgumentList = @()
    )

    process {
        $resolveParameters = @{
            ParameterSetName = $PSCmdlet.ParameterSetName
            Path = $Path
            LiteralPath = $LiteralPath
            DenyMultiplePaths = $true
        }
        $fullPath = Resolve-WUPathFromParameter @resolveParameters |
            ConvertTo-WUFullPath
        Assert-WUPathProperty -LiteralPath $fullPath -Leaf
        if ([System.IO.Path]::GetExtension($fullPath) -ine '.ps1') {
            throw "The script must use the .ps1 extension: $fullPath"
        }
        Assert-WUPSScript -LiteralPath $fullPath

        $windowsPowerShell = Get-Command -Name 'powershell.exe' -CommandType Application -ErrorAction Stop
        $escapedPath = $fullPath.Replace("'", "''")
        $scriptCommand = "& '$escapedPath'"
        foreach ($argument in $ArgumentList) {
            $escapedArgument = $argument.Replace("'", "''")
            $scriptCommand += " '$escapedArgument'"
        }
        $encodedCommand = [Convert]::ToBase64String([System.Text.Encoding]::Unicode.GetBytes($scriptCommand))
        $processArguments = @('-NoProfile', '-EncodedCommand', $encodedCommand)

        if ($PSCmdlet.ShouldProcess($fullPath, 'Start PowerShell script as administrator')) {
            Start-Process -FilePath $windowsPowerShell.Source -ArgumentList $processArguments -Verb 'RunAs'
        }
    }
}
