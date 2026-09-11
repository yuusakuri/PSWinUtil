function Assert-WUCommand {
    <#
    .SYNOPSIS
    Throws when a named command is unavailable on PATH.

    .DESCRIPTION
    Throws an error when PowerShell cannot resolve the specified command name.

    .PARAMETER Name
    Specifies the command name to find.

    .EXAMPLE
    Assert-WUCommand -Name 'git'

    Throws when git is unavailable on PATH.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true, Position = 0)]
        [ValidateNotNullOrEmpty()]
        [string]$Name
    )

    if (-not (Test-WUCommand -Name $Name)) {
        throw "Command '$Name' is not available."
    }
}
