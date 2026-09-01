$repositoryRoot = Split-Path -Path $PSScriptRoot -Parent
$manifestPath = Join-Path -Path $repositoryRoot -ChildPath 'output/PSWinUtil/PSWinUtil.psd1'
Import-Module -Name $manifestPath -Force -ErrorAction Stop
