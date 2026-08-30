function ConvertTo-WUNativeCommandArgument {
    <#
    .SYNOPSIS
    Converts values for native command arguments.

    .DESCRIPTION
    Preserves an empty native command argument in Windows PowerShell by returning an explicit pair of quotation marks. Other values and PowerShell editions are returned unchanged.

    .PARAMETER Argument
    Specifies one or more native command argument values to convert.

    .EXAMPLE
    ConvertTo-WUNativeCommandArgument -Argument ''

    Returns an argument representation that preserves an empty value.

    .EXAMPLE
    'first', '', 'third' | ConvertTo-WUNativeCommandArgument

    Converts each argument value received from the pipeline.

    .INPUTS
    System.String

    .OUTPUTS
    System.String
    #>
    [CmdletBinding()]
    [OutputType([string])]
    param(
        [Parameter(
            Mandatory = $true,
            Position = 0,
            ValueFromPipeline = $true,
            ValueFromPipelineByPropertyName = $true
        )]
        [AllowEmptyString()]
        [ValidateNotNull()]
        [string[]]$Argument
    )

    process {
        foreach ($inputArgument in $Argument) {
            if ($PSVersionTable.PSEdition -eq 'Desktop' -and $inputArgument.Length -eq 0) {
                '""'
            } else {
                $inputArgument
            }
        }
    }
}
