function Test-WUCommand {
    <#
    .SYNOPSIS
    Tests whether a command is available.

    .DESCRIPTION
    Returns whether PowerShell can resolve the specified command name.

    .PARAMETER Name
    Specifies the command name to find.

    .EXAMPLE
    Test-WUCommand -Name 'git'

    Returns True when git is available on PATH.
    #>
    [CmdletBinding()]
    [OutputType([bool])]
    param(
        [Parameter(Mandatory = $true, Position = 0)]
        [ValidateNotNullOrEmpty()]
        [string]$Name
    )

    $null -ne (Get-Command -Name $Name -ErrorAction Ignore)
}
