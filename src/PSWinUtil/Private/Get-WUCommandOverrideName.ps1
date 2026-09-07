function Get-WUCommandOverrideName {
    <#
    .SYNOPSIS
    Gets the names of the commands overridden by PSWinUtil.

    .DESCRIPTION
    Returns the Windows PowerShell command names that PSWinUtil replaces with a proxy function. The module import and the override state commands share this single list.

    .EXAMPLE
    Get-WUCommandOverrideName

    Returns Get-Content, Set-Content, Add-Content, Out-File, and Invoke-WebRequest.

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
    'Invoke-WebRequest'
}
