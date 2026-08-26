function Get-Content {
    <#
    .SYNOPSIS
    Gets content with UTF-8 as the default file encoding.

    .DESCRIPTION
    Proxies Microsoft.PowerShell.Management Get-Content with the Windows PowerShell 5.1 parameters. File system text is decoded as UTF-8 when Encoding is omitted. An explicit Encoding value and non-file-system providers keep the original cmdlet behavior. The original cmdlet remains available as Microsoft.PowerShell.Management\Get-Content. PSWinUtil exports this function only in Windows PowerShell Desktop.

    .PARAMETER Path
    Specifies one or more paths and permits wildcard characters.

    .PARAMETER LiteralPath
    Specifies one or more paths without wildcard interpretation.

    .PARAMETER ReadCount
    Specifies how many lines are sent through the pipeline at one time.

    .PARAMETER TotalCount
    Specifies how many lines are read from the beginning.

    .PARAMETER Tail
    Specifies how many lines are read from the end.

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

    .PARAMETER Delimiter
    Specifies the file system content delimiter.

    .PARAMETER Wait
    Waits for additional file content.

    .PARAMETER Raw
    Returns the complete file as one string.

    .PARAMETER Encoding
    Specifies an explicit input encoding instead of the UTF-8 default.

    .PARAMETER Stream
    Specifies an alternate NTFS data stream.

    .PARAMETER UseTransaction
    Includes the command in an active transaction where supported.

    .EXAMPLE
    Get-Content -Path 'C:\Data\message.txt'

    Reads the file as UTF-8 when Encoding is omitted.

    .INPUTS
    System.String

    .OUTPUTS
    System.String
    #>
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute(
        'PSAvoidOverwritingBuiltInCmdlets',
        '',
        Justification = 'The public proxy intentionally changes the Windows PowerShell default file encoding.'
    )]
    [CmdletBinding(DefaultParameterSetName = 'Path', SupportsTransactions = $true)]
    param(
        [Parameter(ValueFromPipelineByPropertyName = $true)]
        [long]$ReadCount,

        [Parameter(ValueFromPipelineByPropertyName = $true)]
        [Alias('First', 'Head')]
        [ValidateRange(0, [long]::MaxValue)]
        [long]$TotalCount,

        [Parameter(ValueFromPipelineByPropertyName = $true)]
        [Alias('Last')]
        [ValidateRange(0, [int]::MaxValue)]
        [int]$Tail,

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
        Get-WUFileCommandDynamicParameter -CommandName 'Get-Content' -BoundParameter $PSBoundParameters
    }

    begin {
        $outBuffer = $null
        if ($PSBoundParameters.TryGetValue('OutBuffer', [ref]$outBuffer)) {
            $PSBoundParameters.OutBuffer = 1
        }
        if (
            $MyInvocation.MyCommand.Parameters.ContainsKey('Encoding') -and
            -not $PSBoundParameters.ContainsKey('Encoding')
        ) {
            $PSBoundParameters.Encoding = 'UTF8'
        }

        $wrappedCommand = $ExecutionContext.InvokeCommand.GetCommand(
            'Microsoft.PowerShell.Management\Get-Content',
            [System.Management.Automation.CommandTypes]::Cmdlet
        )
        $commandScript = { & $wrappedCommand @PSBoundParameters }
        $steppablePipeline = $commandScript.GetSteppablePipeline($MyInvocation.CommandOrigin)
        $steppablePipeline.Begin($PSCmdlet)
    }

    process {
        try {
            $steppablePipeline.Process($_)
        } catch {
            $steppablePipeline.Dispose()
            throw
        }
    }

    end {
        try {
            $steppablePipeline.End()
        } finally {
            $steppablePipeline.Dispose()
        }
    }
}
