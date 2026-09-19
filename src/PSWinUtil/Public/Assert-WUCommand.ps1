function Assert-WUCommand {
    <#
    .SYNOPSIS
    Throws when a named command is unavailable on PATH.

    .DESCRIPTION
    Throws an error when PowerShell cannot resolve any specified command name.

    .PARAMETER Name
    Specifies one or more command names to find.

    .EXAMPLE
    Assert-WUCommand -Name 'git'

    Throws when git is unavailable on PATH.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true, Position = 0)]
        [ValidateNotNullOrEmpty()]
        [string[]]$Name
    )

    foreach ($commandName in $Name) {
        if (-not (Test-WUCommand -Name $commandName)) {
            throw "Command '$commandName' is not available."
        }
    }
}
