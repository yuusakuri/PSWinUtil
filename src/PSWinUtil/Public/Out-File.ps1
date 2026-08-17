function Out-File {
    <#
    .SYNOPSIS
    Sends formatted output to UTF-8 without BOM and LF by default.

    .DESCRIPTION
    Proxies Microsoft.PowerShell.Utility Out-File with the Windows PowerShell 5.1 parameters. Output uses UTF-8 when Encoding is omitted or UTF8 is specified, then the completed file is normalized to UTF-8 without BOM and LF. Other explicit encodings keep the original cmdlet behavior. The original cmdlet remains available as Microsoft.PowerShell.Utility\Out-File.

    .PARAMETER FilePath
    Specifies the output file path.

    .PARAMETER LiteralPath
    Specifies the output file path without wildcard interpretation.

    .PARAMETER Encoding
    Specifies an explicit output encoding. UTF8 still produces no BOM.

    .PARAMETER Append
    Appends output to an existing file.

    .PARAMETER Force
    Allows writing to a read-only file where supported.

    .PARAMETER NoClobber
    Prevents replacement of an existing file.

    .PARAMETER Width
    Specifies the maximum number of characters in each formatted line.

    .PARAMETER NoNewline
    Omits separators and the final newline.

    .PARAMETER InputObject
    Specifies objects sent to the file.

    .EXAMPLE
    Get-Process | Out-File -FilePath 'C:\Logs\process.txt'

    Writes formatted output as UTF-8 without BOM and LF.

    .INPUTS
    System.Management.Automation.PSObject

    .OUTPUTS
    None
    #>
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute(
        'PSAvoidOverwritingBuiltInCmdlets',
        '',
        Justification = 'The public proxy intentionally changes the Windows PowerShell default file format.'
    )]
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute(
        'PSShouldProcess',
        '',
        Justification = 'The proxy approves the operation once and suppresses delegated confirmation.'
    )]
    [CmdletBinding(
        DefaultParameterSetName = 'ByPath',
        SupportsShouldProcess = $true,
        ConfirmImpact = 'Medium'
    )]
    param(
        [Parameter(ParameterSetName = 'ByPath', Mandatory = $true, Position = 0)]
        [Alias('Path')]
        [string]$FilePath,

        [Parameter(
            ParameterSetName = 'ByLiteralPath',
            Mandatory = $true,
            ValueFromPipelineByPropertyName = $true
        )]
        [Alias('PSPath', 'LP')]
        [string]$LiteralPath,

        [Parameter(Position = 1)]
        [ValidateSet(
            'ASCII',
            'BigEndianUnicode',
            'Default',
            'OEM',
            'String',
            'Unicode',
            'Unknown',
            'UTF7',
            'UTF8',
            'UTF32'
        )]
        [string]$Encoding,

        [Parameter()]
        [switch]$Append,

        [Parameter()]
        [switch]$Force,

        [Parameter()]
        [Alias('NoOverwrite')]
        [switch]$NoClobber,

        [Parameter()]
        [ValidateRange(2, [int]::MaxValue)]
        [int]$Width,

        [Parameter()]
        [switch]$NoNewline,

        [Parameter(ValueFromPipeline = $true)]
        [psobject]$InputObject
    )

    begin {
        $selectedPath = $FilePath
        if ($PSCmdlet.ParameterSetName -eq 'ByLiteralPath') {
            $selectedPath = $LiteralPath
        }
        $action = 'Write formatted file content'
        if ($Append) {
            $action = 'Append formatted file content'
        }
        $approved = $PSCmdlet.ShouldProcess($selectedPath, $action)
        if (-not $approved) {
            return
        }

        $outBuffer = $null
        if ($PSBoundParameters.TryGetValue('OutBuffer', [ref]$outBuffer)) {
            $PSBoundParameters.OutBuffer = 1
        }
        if (-not $PSBoundParameters.ContainsKey('Encoding')) {
            $PSBoundParameters.Encoding = 'UTF8'
        }
        $normalizeOutput = $PSBoundParameters.Encoding -ieq 'UTF8'

        if ($normalizeOutput -and $Append -and -not $NoClobber -and (Test-Path -LiteralPath $selectedPath -PathType Leaf)) {
            $existingPath = ConvertTo-WUFullPath -Path $selectedPath
            Convert-WUTextFileToUtf8Lf -Path $existingPath
        }

        $null = $PSBoundParameters.Remove('WhatIf')
        $PSBoundParameters.Confirm = $false
        $wrappedCommand = $ExecutionContext.InvokeCommand.GetCommand(
            'Microsoft.PowerShell.Utility\Out-File',
            [System.Management.Automation.CommandTypes]::Cmdlet
        )
        $commandScript = { & $wrappedCommand @PSBoundParameters }
        $steppablePipeline = $commandScript.GetSteppablePipeline($MyInvocation.CommandOrigin)
        $steppablePipeline.Begin($PSCmdlet)
    }

    process {
        if ($approved) {
            $steppablePipeline.Process($_)
        }
    }

    end {
        if (-not $approved) {
            return
        }
        $steppablePipeline.End()
        if ($normalizeOutput) {
            $fullPath = ConvertTo-WUFullPath -Path $selectedPath
            Convert-WUTextFileToUtf8Lf -Path $fullPath
        }
    }
}
