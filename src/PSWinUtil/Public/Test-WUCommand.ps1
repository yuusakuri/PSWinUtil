function Test-WUCommand {
    <#
    .SYNOPSIS
    Tests whether a command is available.

    .DESCRIPTION
    Returns whether PowerShell can resolve each specified command name.

    .PARAMETER Name
    Specifies one or more command names to find.

    .EXAMPLE
    Test-WUCommand -Name 'git'

    Returns True when git is available on PATH.
    #>
    [CmdletBinding()]
    [OutputType([bool])]
    param(
        [Parameter(Mandatory = $true, Position = 0)]
        [ValidateNotNullOrEmpty()]
        [string[]]$Name
    )

    foreach ($commandName in $Name) {
        $null -ne (Get-Command -Name $commandName -ErrorAction Ignore)
    }
}
