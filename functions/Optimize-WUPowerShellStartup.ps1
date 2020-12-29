<#
  .SYNOPSIS
  Speed up PowerShell startup by precompiling .NET assemblies with ngen.exe.

  .DESCRIPTION
  Administrator privileges are required to run this script.

  Every time, PowerShell compiles and loads the .NET assembly at startup. Speed up PowerShell startup by precompiling .NET assemblies with ngen.exe.

  .EXAMPLE
  PS C:\>Optimize-WUPowerShellStartup

#>
[CmdletBinding()]
param (
)

Set-StrictMode -Version 'Latest'

if (!(Test-WUAdmin)) {
    Write-Error 'Administrator privileges are required to run this script.'
    return
}

if (($PSEdition -eq 'Core')) {
    Write-Error 'This script only works with Windows PowerShell.'
    return
}

$ngenPath = Join-Path ([Runtime.InteropServices.RuntimeEnvironment]::GetRuntimeDirectory()) 'ngen.exe'

Write-Host 'Compiling .NET assemblies with ngen.exe.'

[System.AppDomain]::CurrentDomain.GetAssemblies() |
Select-Object -ExpandProperty Location |
ForEach-Object {
    & $ngenPath install $_ /nologo
}
