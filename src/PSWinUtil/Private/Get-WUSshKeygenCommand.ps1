function Get-WUSshKeygenCommand {
    <#
    .SYNOPSIS
    Gets the Windows OpenSSH key generator command.

    .DESCRIPTION
    Finds ssh-keygen.exe as an application and returns the first matching command. A missing command reports an error.

    .EXAMPLE
    Get-WUSshKeygenCommand

    Returns the ssh-keygen.exe command used for SSH key operations.

    .INPUTS
    None

    .OUTPUTS
    System.Management.Automation.ApplicationInfo
    #>
    [CmdletBinding()]
    [OutputType([System.Management.Automation.ApplicationInfo])]
    param()

    Get-Command -Name 'ssh-keygen.exe' -CommandType Application -ErrorAction Stop |
        Select-Object -First 1
}
