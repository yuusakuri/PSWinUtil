function ConvertTo-WUSshKeygenArgument {
    <#
    .SYNOPSIS
    Converts a value for ssh-keygen.exe.

    .DESCRIPTION
    Preserves an empty native argument in Windows PowerShell by returning an explicit pair of quotation marks. Other values and PowerShell editions are returned unchanged.

    .PARAMETER Argument
    Specifies the argument value to convert.

    .EXAMPLE
    ConvertTo-WUSshKeygenArgument -Argument ''

    Returns an argument representation that preserves an empty value.

    .INPUTS
    None

    .OUTPUTS
    System.String
    #>
    [CmdletBinding()]
    [OutputType([string])]
    param(
        [Parameter(Mandatory = $true)]
        [AllowEmptyString()]
        [string]$Argument
    )

    if ($PSVersionTable.PSEdition -eq 'Desktop' -and $Argument.Length -eq 0) {
        '""'
        return
    }

    $Argument
}
