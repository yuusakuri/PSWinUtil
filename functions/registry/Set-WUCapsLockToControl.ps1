<#
  .SYNOPSIS
  Remap capslock key to control key.

  .DESCRIPTION
  remap capslock key to control key By rewriting the registry
#>
[CmdletBinding(SupportsShouldProcess)]
param (
)

$hexified = "00,00,00,00,00,00,00,00,02,00,00,00,1d,00,3a,00,00,00,00,00".Split(',') | % { "0x$_" }

$kbLayout = 'HKLM:\System\CurrentControlSet\Control\Keyboard Layout'

Set-CRegistryKeyValue -Path $kbLayout -Name "Scancode Map" -Binary ([byte[]]$hexified)
