<#
  .SYNOPSIS
  Register the file to startup.

  .DESCRIPTION
  Register the file to startup. You can specify the arguments to pass to the file, the value name of the registry, and whether the target user is the current user or all users.

  This cmdlet works with registry.

  .EXAMPLE
  PS C:\>Register-WUStartup -LiteralPath 'C:\Windows\System32\WindowsPowerShell\v1.0\powershell.exe' -Valuename powershell -Argument '-NoLogo -Command ls' -Scope 'LocalMachine'

  In this example, we want all users to start powershell with arguments at startup.
#>

[CmdletBinding(
    SupportsShouldProcess,
    DefaultParameterSetName = 'Path'
)]
param (
    # Specify the location of the file to be registered in the startup. Wildcards are permitted.
    [Parameter(Mandatory,
        Position = 0,
        ParameterSetName = 'Path',
        ValueFromPipeline,
        ValueFromPipelineByPropertyName)]
    [ValidateNotNullOrEmpty()]
    [SupportsWildcards()]
    [string]
    $Path,

    # Specify the location of the file to be registered in the startup. Unlike the Path parameter, the value of the LiteralPath parameter is used exactly as it is typed. No characters are interpreted as wildcards. If the path includes escape characters, enclose it in single quotation marks. Single quotation marks tell Windows PowerShell not to interpret any characters as escape sequences.
    [Parameter(Mandatory,
        Position = 0,
        ParameterSetName = 'LiteralPath',
        ValueFromPipelineByPropertyName)]
    [Alias('PSPath')]
    [ValidateNotNullOrEmpty()]
    [string]
    $LiteralPath,

    # Specify this parameter if you want the value to be empty.
    [Parameter(Position = 0,
        ParameterSetName = 'Empty')]
    [switch]
    $Empty,

    # Specify the Value name of the registry to register. If nothing is specified, this value will be the file base name.
    [string]
    $Valuename,

    # Specify the argument to be passed to the file at startup.
    [Parameter(ParameterSetName = 'Path')]
    [Parameter(ParameterSetName = 'LiteralPath')]
    [string]
    $Argument,

    # Specifies the scope that is affected. The default scope is CurrentUser.
    [ValidateSet('LocalMachine', 'CurrentUser')]
    [string]
    $Scope = 'CurrentUser'
)

Set-StrictMode -Version 'Latest'
$registryHash = Get-WURegistryHash
if (!$registryHash) {
    return
}

$paths = @()
if ($psCmdlet.ParameterSetName -eq 'Empty') {
    $paths += ""
}
elseif ($psCmdlet.ParameterSetName -eq 'Path') {
    $paths += ConvertTo-WUFullPath -Path $Path
}
else {
    $paths += ConvertTo-WUFullPath -LiteralPath $LiteralPath
}

if ($paths.Count -ne 1) {
    Write-Error 'The Path must specify a single location.'
    return
}

foreach ($aPath in $paths) {
    if ($Valuename) {
        $registryHash.Startup.$Scope.Valuename = $Valuename
    }
    else {
        $registryHash.Startup.$Scope.Valuename = Split-Path $aPath -Leaf
    }

    $registryHash.Startup.$Scope.Data = '"{0}"' -f $aPath
    if ($Argument) {
        $registryHash.Startup.$Scope.Data = '{0} {1}' -f $registryHash.Startup.$Scope.Data, $Argument
    }

    Set-WURegistryFromHash -RegistryHash $registryHash -Scope $Scope
}
