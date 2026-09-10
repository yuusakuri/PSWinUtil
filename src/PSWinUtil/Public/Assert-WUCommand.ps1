function Assert-WUCommand {
    <#
    .SYNOPSIS
    Requires a command to be available.

    .PARAMETER Name
    Specifies the command name to find.
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
