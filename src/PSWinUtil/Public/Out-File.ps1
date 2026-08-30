function Out-File {
    <#
    .SYNOPSIS
    Sends formatted output to UTF-8 without BOM and LF by default.

    .DESCRIPTION
    Proxies Microsoft.PowerShell.Utility Out-File with the Windows PowerShell 5.1 parameters. Output uses UTF-8 without BOM and LF when Encoding is omitted or UTF8 is specified. Other explicit encodings keep the original cmdlet behavior. The original cmdlet remains available as Microsoft.PowerShell.Utility\Out-File. PSWinUtil exports this function only in Windows PowerShell Desktop.

    Windows PowerShell 5.1 language redirection resolves this function but keeps its own target file handle after the function finishes. Use an explicit pipeline to Out-File when the same script must access the file immediately. Redirection operators are not covered by this function guarantee.

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
        $targetPath = $FilePath
        if ($PSBoundParameters.ContainsKey('LiteralPath')) {
            $targetPath = $LiteralPath
        }
        $action = 'Write formatted file content'
        if ($Append) {
            $action = 'Append formatted file content'
        }
        $approved = $PSCmdlet.ShouldProcess($targetPath, $action)
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

        if ($normalizeOutput) {
            $fullPath = ConvertTo-WUFullPath -Path $targetPath
            $targetExists = [System.IO.File]::Exists($fullPath)
            if ($NoClobber -and -not $Append -and $targetExists) {
                throw "The file '$targetPath' already exists."
            }
            if ($Append -and $targetExists) {
                Convert-WUTextFileToUtf8Lf -Path $fullPath
            }

            $originalAttributes = $null
            if ($targetExists) {
                $originalAttributes = [System.IO.File]::GetAttributes($fullPath)
                $isReadOnly = ($originalAttributes -band [System.IO.FileAttributes]::ReadOnly) -ne 0
                if ($isReadOnly -and -not $Force) {
                    throw "The file '$targetPath' is read-only. Use Force to write it."
                }
                if ($isReadOnly) {
                    $writableAttributes = $originalAttributes -band (-bnot [System.IO.FileAttributes]::ReadOnly)
                    [System.IO.File]::SetAttributes($fullPath, $writableAttributes)
                }
            }

            $fileMode = [System.IO.FileMode]::Create
            if ($Append) {
                $fileMode = [System.IO.FileMode]::Append
            }
            try {
                $fileStream = [System.IO.FileStream]::new(
                    $fullPath,
                    $fileMode,
                    [System.IO.FileAccess]::Write,
                    [System.IO.FileShare]::Read
                )
                $streamWriter = [System.IO.StreamWriter]::new(
                    $fileStream,
                    [System.Text.UTF8Encoding]::new($false)
                )
                $streamWriter.NewLine = "`n"
            } catch {
                if ($null -ne $originalAttributes) {
                    [System.IO.File]::SetAttributes($fullPath, $originalAttributes)
                }
                throw
            }

            $formatParameters = @{ Stream = $true }
            if ($PSBoundParameters.ContainsKey('Width')) {
                $formatParameters.Width = $Width
            }
            $outStringCommand = $ExecutionContext.InvokeCommand.GetCommand(
                'Microsoft.PowerShell.Utility\Out-String',
                [System.Management.Automation.CommandTypes]::Cmdlet
            )
            $formatScript = { & $outStringCommand @formatParameters }
            $formatPipeline = $formatScript.GetSteppablePipeline($MyInvocation.CommandOrigin)
            $formatPipeline.Begin($true)

            $writeLines = {
                param([object[]]$Line)

                foreach ($inputLine in $Line) {
                    if ($NoNewline) {
                        $streamWriter.Write([string]$inputLine)
                    } else {
                        $streamWriter.WriteLine([string]$inputLine)
                    }
                }
            }
            $closeOutput = {
                if ($null -ne $formatPipeline) {
                    $formatPipeline.Dispose()
                    $formatPipeline = $null
                }
                if ($null -ne $streamWriter) {
                    $streamWriter.Dispose()
                    $streamWriter = $null
                }
                if ($null -ne $originalAttributes) {
                    [System.IO.File]::SetAttributes($fullPath, $originalAttributes)
                    $originalAttributes = $null
                }
            }
        } else {
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
    }

    process {
        if ($approved) {
            try {
                if ($normalizeOutput) {
                    & $writeLines -Line @($formatPipeline.Process($_))
                } else {
                    $steppablePipeline.Process($_)
                }
            } catch {
                if ($normalizeOutput) {
                    & $closeOutput
                } else {
                    $steppablePipeline.Dispose()
                }
                throw
            }
        }
    }

    end {
        if (-not $approved) {
            return
        }
        if ($normalizeOutput) {
            try {
                & $writeLines -Line @($formatPipeline.End())
            } finally {
                & $closeOutput
            }
        } else {
            try {
                $steppablePipeline.End()
            } finally {
                $steppablePipeline.Dispose()
            }
        }
    }
}
