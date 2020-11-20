<#
    .SYNOPSIS
    Search for paths in all locations.

    .DESCRIPTION
    Search the path everywhere using command path or es.exe.

    .OUTPUTS
    System.String.

    Returns the path found by searching.

    .EXAMPLE
    PS C:\> Find-WUPath 'powershell.exe'

    In this example, Finds and returns the path where the leaf contains powershell.exe.

    .EXAMPLE
    PS C:\> Find-WUPath 'powershell.exe' -Strict

    In this example, Finds and returns the path where the leaf exactly matches powershell.exe.

    .EXAMPLE
    PS C:\> Find-WUPath 'PowerShell\v1.0\powershell.exe' -Strict

    In this example, Searches for and returns a path whose leaf exactly matches powershell.exe and whose parent path contains PowerShell\v1.0.

    .EXAMPLE
    PS C:\> Find-WUPath 'powershell.exe' -Strict -Exclude 'C:\Windows\WinSxS'

    In this example, Searches for and returns a path that does not contain C:\Windows\WinSxS and leaves exactly match powershell.exe.

    .EXAMPLE
    PS C:\> Find-WUPath 'powershell.exe' -Program

    In this example, powershell.exe is searched for in the order of command, start menu shortcut file link destination, es.exe, and the path containing powershell.exe in the leaf is returned.
#>

[CmdletBinding()]
param (
  # Specify the character string contained in the leaf of the path to be searched. In addition, the strings contained in its parent directory can be specified before the leaf, separated by / or \. However, if -Strict is specified, the path with exact leaf matches will be searched. Also, wildcards are not supported.
  [Parameter(Mandatory,
    Position = 0,
    ValueFromPipeline,
    ValueFromPipelineByPropertyName)]
  [ValidateNotNullOrEmpty()]
  [string[]]
  $Name,

  # Excludes paths that include the specified string. The following paths are excluded by default.
  <#
    'C:\Windows\SysWOW64'
    'C:\Windows\WinSxS'
    "$env:LOCALAPPDATA\Microsoft\Windows\FileHistory"
  #>
  [string[]]
  $Exclude = @(
    'C:\Windows\SysWOW64'
    'C:\Windows\WinSxS'
    "$env:LOCALAPPDATA\Microsoft\Windows\FileHistory"
  ),

  # Search for a path that has an exact leaf match.
  [switch]
  $Strict,

  # Searches the command from the leaf of the path specified by -Name and returns the path if found. If not found, searches all locations by using es.exe.
  [switch]
  $Program
)

Set-StrictMode -Version 'Latest'

# 結果を処理するスクリプト
$isCompleated = {
  param (
    [string[]]
    $AddPath
  )

  if (!$AddPath) {
    return $false
  }

  $resultPaths.AddRange($AddPath)
  $resultItems = Get-Item -LiteralPath $resultPaths -ErrorAction Ignore

  if ($Exclude) {
    foreach ($aExclude in $Exclude) {
      $resultItems = $resultItems | Where-Object { !(Select-String -InputObject $_.FullName -SimpleMatch $aExclude) }
    }
  }

  $resultItems = $patterns | ForEach-Object {
    $pattern = $_

    $completedItem = $resultItems |
    Where-Object {
      if (!$pattern.Parent) {
        return $true
      }
      return Select-String -InputObject (Split-Path $_ -Parent) -SimpleMatch $pattern.Parent
    } |
    Where-Object {
      if ($Strict) {
        return $_.Name -eq $pattern.Leaf
      }
      return Select-String -InputObject $_.Name -SimpleMatch $pattern.Leaf
    }

    if ($completedItem) {
      $completedItem
      $completedLeafs.add($pattern.Leaf) | Out-Null
    }
  }

  $resultPaths.Clear()
  if (!$resultItems) {
    return $false
  }
  $resultPaths.AddRange([string[]](Convert-Path -LiteralPath $resultItems.FullName | Select-Object -Unique))

  # $leafsを未取得のもので上書き
  [string[]]$leafs = $leafs | Where-Object { $completedLeafs -notcontains $_ }

  $completedLeafs.Clear()

  return !$leafs
}

# パスセパレータを\で統一
$Name = $Name -replace '/', '\'

$patterns = $Name | ForEach-Object {
  @{
    Leaf   = Split-Path $_ -Leaf
    Parent = Split-Path $_ -Parent
  }
}

$leafs = $patterns.Leaf
$resultPaths = New-Object System.Collections.ArrayList
$completedLeafs = New-Object System.Collections.ArrayList

if ($Program) {
  # コマンドから探す
  [string[]]$cmdPaths = Get-Command $leafs -ErrorAction Ignore | Select-Object -ExpandProperty Path

  if ($cmdPaths) {
    $cmdResultPaths = @()
    [string[]]$scoopShimPaths = $cmdPaths |
    Where-Object {
      (Split-Path $_ -Parent) -like '*scoop\shims' -and
      (Split-Path $_ -Leaf) -match '\.exe$'
    }
    $GeneralCmdPaths = $cmdPaths | Where-Object { $scoopShimPaths -notcontains $_ }

    $cmdResultPaths += $GeneralCmdPaths

    if ($scoopShimPaths) {
      if ((Get-Command -Name scoop -ErrorAction Ignore)) {
        $scoopCmdPaths = Split-Path $scoopShimPaths -Leaf | ForEach-Object {
          scoop which ($_ -replace '\.exe$', '')
        }
        $cmdResultPaths += $scoopCmdPaths
      }
      else {
        $cmdResultPaths += $scoopShimPaths
      }
    }

    if ((& $isCompleated -AddPath $cmdResultPaths)) {
      return $resultPaths
    }
  }

  # ショートカットから探す
  $lnkDirs = @(
    "$env:APPDATA\Microsoft\Windows\Start Menu"
    "C:\ProgramData\Microsoft\Windows\Start Menu"
  )

  $lnkResultPaths = Get-WULnkTarget -LiteralPath (Get-ChildItem -LiteralPath $lnkDirs -Recurse | Where-Object { $_.Extension -eq '.lnk' } | Select-Object -ExpandProperty FullName) -WarningAction Ignore

  if ((& $isCompleated -AddPath $lnkResultPaths)) {
    return $resultPaths
  }
}

# es.exeで探す
[string[]]$esResultPaths = $leafs | ForEach-Object {
  es.exe $_
}

if ((& $isCompleated -AddPath $esResultPaths)) {
  return $resultPaths
}

return $resultPaths
