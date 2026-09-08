function Get-WUCommandOverrideName {
    <#
    .SYNOPSIS
    Gets the names of the commands overridden by PSWinUtil.

    .DESCRIPTION
    Returns the Windows PowerShell command names that PSWinUtil replaces with a proxy function. The module import keeps and places every proxy from this single list, and the public override commands accept the same names through their own ValidateSet.

    .EXAMPLE
    Get-WUCommandOverrideName

    Returns Get-Content, Set-Content, Add-Content, and Out-File.

    .INPUTS
    None

    .OUTPUTS
    System.String
    #>
    [CmdletBinding()]
    [OutputType([string])]
    param()

    'Get-Content'
    'Set-Content'
    'Add-Content'
    'Out-File'
}
