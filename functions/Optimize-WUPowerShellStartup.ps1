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

if ((Test-WUAdmin)) {
  Write-Error 'Administrator privileges are required to run this script.'
  return
}

$ngenPath = Join-Path ([Runtime.InteropServices.RuntimeEnvironment]::GetRuntimeDirectory()) 'ngen.exe'

[System.AppDomain]::CurrentDomain.GetAssemblies() | ForEach-Object {
  if (!$_.location) {
    continue
  }

  & $ngenPath install $_.location /nologo
}
