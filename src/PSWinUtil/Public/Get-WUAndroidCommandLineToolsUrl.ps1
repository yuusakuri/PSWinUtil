function Get-WUAndroidCommandLineToolsUrl {
    <#
    .SYNOPSIS
    Gets the current Android command-line tools URL for Windows.

    .DESCRIPTION
    Reads the official Android Studio download page, finds the current Windows command-line tools package name, and returns its Google repository URL.

    .EXAMPLE
    Get-WUAndroidCommandLineToolsUrl

    Returns the current Windows command-line tools ZIP URL.

    .INPUTS
    None

    .OUTPUTS
    System.String
    #>
    [CmdletBinding()]
    [OutputType([string])]
    param()

    (Get-WUAndroidCommandLineToolsPackage).Uri.AbsoluteUri
}
