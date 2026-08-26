function Add-Content {
    <#
    .SYNOPSIS
    Appends content with UTF-8 without BOM and LF by default.

    .DESCRIPTION
    Proxies Microsoft.PowerShell.Management Add-Content with the Windows PowerShell 5.1 parameters. File system text uses UTF-8 when Encoding is omitted or UTF8 is specified, then the completed file is normalized to UTF-8 without BOM and LF. Other encodings, alternate streams, and non-file-system providers keep the original cmdlet behavior. The original cmdlet remains available as Microsoft.PowerShell.Management\Add-Content. PSWinUtil exports this function only in Windows PowerShell Desktop.

    .PARAMETER Value
    Specifies the content appended to each selected item.

    .PARAMETER PassThru
    Returns the appended content.

    .PARAMETER Path
    Specifies one or more paths and permits wildcard characters.

    .PARAMETER LiteralPath
    Specifies one or more paths without wildcard interpretation.

    .PARAMETER Filter
    Specifies a provider filter.

    .PARAMETER Include
    Specifies path patterns to include.

    .PARAMETER Exclude
    Specifies path patterns to exclude.

    .PARAMETER Force
    Allows provider operations permitted by the original cmdlet.

    .PARAMETER Credential
    Specifies provider credentials where supported.

    .PARAMETER NoNewline
    Omits separators and the final newline.

    .PARAMETER Encoding
    Specifies an explicit output encoding. UTF8 still produces no BOM.

    .PARAMETER Stream
    Specifies an alternate NTFS data stream and keeps the original behavior.

    .PARAMETER UseTransaction
    Includes the command in an active transaction where supported.

    .EXAMPLE
    Add-Content -Path 'C:\Data\message.txt' -Value 'next message'

    Appends UTF-8 without BOM and uses LF for line endings.

    .INPUTS
    System.Object

    .OUTPUTS
    System.String
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
        DefaultParameterSetName = 'Path',
        SupportsShouldProcess = $true,
        ConfirmImpact = 'Medium',
        SupportsTransactions = $true
    )]
    param(
        [Parameter(
            Mandatory = $true,
            Position = 1,
            ValueFromPipeline = $true,
            ValueFromPipelineByPropertyName = $true
        )]
        [AllowNull()]
        [AllowEmptyCollection()]
        [object[]]$Value,

        [Parameter()]
        [switch]$PassThru,

        [Parameter(
            ParameterSetName = 'Path',
            Mandatory = $true,
            Position = 0,
            ValueFromPipelineByPropertyName = $true
        )]
        [SupportsWildcards()]
        [string[]]$Path,

        [Parameter(
            ParameterSetName = 'LiteralPath',
            Mandatory = $true,
            ValueFromPipelineByPropertyName = $true
        )]
        [Alias('PSPath', 'LP')]
        [string[]]$LiteralPath,

        [Parameter()]
        [string]$Filter,

        [Parameter()]
        [string[]]$Include,

        [Parameter()]
        [string[]]$Exclude,

        [Parameter()]
        [switch]$Force,

        [Parameter(ValueFromPipelineByPropertyName = $true)]
        [System.Management.Automation.CredentialAttribute()]
        [pscredential]$Credential
    )

    dynamicparam {
        Get-WUFileCommandDynamicParameter -CommandName 'Add-Content' -BoundParameter $PSBoundParameters
    }

    begin {
        $selectedPaths = @()
        if ($null -ne $Path) {
            $selectedPaths += $Path
        }
        if ($null -ne $LiteralPath) {
            $selectedPaths += $LiteralPath
        }
        $targetDescription = $selectedPaths -join ', '
        $approved = $PSCmdlet.ShouldProcess($targetDescription, 'Add file content')
        if (-not $approved) {
            return
        }

        $outBuffer = $null
        if ($PSBoundParameters.TryGetValue('OutBuffer', [ref]$outBuffer)) {
            $PSBoundParameters.OutBuffer = 1
        }
        $hasEncodingParameter = $MyInvocation.MyCommand.Parameters.ContainsKey('Encoding')
        if ($hasEncodingParameter -and -not $PSBoundParameters.ContainsKey('Encoding')) {
            $PSBoundParameters.Encoding = 'UTF8'
        }
        $normalizeOutput = $hasEncodingParameter -and
        $PSBoundParameters.Encoding.ToString() -ieq 'UTF8' -and
        -not $PSBoundParameters.ContainsKey('Stream')

        if ($normalizeOutput) {
            foreach ($filePath in @(Get-WUContentFilePath -BoundParameter $PSBoundParameters)) {
                Convert-WUTextFileToUtf8Lf -Path $filePath
            }
        }

        $null = $PSBoundParameters.Remove('WhatIf')
        $PSBoundParameters.Confirm = $false
        $wrappedCommand = $ExecutionContext.InvokeCommand.GetCommand(
            'Microsoft.PowerShell.Management\Add-Content',
            [System.Management.Automation.CommandTypes]::Cmdlet
        )
        $commandScript = { & $wrappedCommand @PSBoundParameters }
        $steppablePipeline = $commandScript.GetSteppablePipeline($MyInvocation.CommandOrigin)
        $steppablePipeline.Begin($PSCmdlet)
    }

    process {
        if ($approved) {
            try {
                $steppablePipeline.Process($_)
            } catch {
                $steppablePipeline.Dispose()
                throw
            }
        }
    }

    end {
        if (-not $approved) {
            return
        }
        try {
            $steppablePipeline.End()
        } finally {
            $steppablePipeline.Dispose()
        }
        if ($normalizeOutput) {
            foreach ($filePath in @(Get-WUContentFilePath -BoundParameter $PSBoundParameters)) {
                Convert-WUTextFileToUtf8Lf -Path $filePath
            }
        }
    }
}
