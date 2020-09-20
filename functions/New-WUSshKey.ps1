<#
  .SYNOPSIS
  Create SSH key.

  .DESCRIPTION
  Create an ssh key using ssh-keygen. This cmdlet use the new OpenSSH format rather than the more compatible PEM format. The new format has increased resistance to brute-force password cracking but is not supported by versions of OpenSSH prior to 6.5.

  .OUTPUTS
  System.String

  Returns the path of the created key file.

  .EXAMPLE
  PS C:\>New-WUSshKey -Path test_rsa

  This example creates test_rsa and test_rsa.pub in the path $env:USERPROFILE/.ssh and returns test_rsa path.

  .LINK
  Edit-WUSshKey
#>

[CmdletBinding()]
param (
  # Specify the location of the key file to be created, relative path from '~/.ssh' or absolute path.
  [Parameter(Mandatory,
    Position = 0,
    ValueFromPipeline,
    ValueFromPipelineByPropertyName)]
  [ValidateNotNullOrEmpty()]
  [string]
  $Path,

  # Specify a comment.
  [string]
  $Comment,

  # Specify a passphrase. Passphrase must be a minimum of 5 characters.
  [Alias('NewPassphrase')]
  [string]
  $Passphrase,

  # Specify bits. The default value is 4096.
  [ValidateNotNullOrEmpty()]
  [int]
  $Bits = 4096,

  # Specify the cipher algorithms type. The default type is rsa.
  [ValidateSet('dsa', 'ecdsa', 'ecdsa-sk', 'ed25519', 'ed25519-sk', 'rsa')]
  [string]
  $Type = 'rsa',

  # Overwrites the key file if it exists.
  [switch]
  $Force
)

Set-StrictMode -Version 'Latest'

# コマンドの引数に空文字を渡す場合にエスケープさせる
$emptyParam = @{
  ''   = """"""
  '''' = """"""
  """" = """"""
}
if ($emptyParam.ContainsKey($Comment)) {
  $Comment = $emptyParam.$Comment
}
if ($emptyParam.ContainsKey($Passphrase)) {
  $Passphrase = $emptyParam.$Passphrase
}
elseif ($Passphrase.Length -le 5) {
  Write-Error 'Passphrase must be a minimum of 5 characters.'
  return
}

# 鍵ファイルのフルパスを取得して親ディレクトリを作成
$keyPath = Resolve-WUFullPath -LiteralPath $Path -BasePath '~/.ssh' -Parents

$keyDir = Split-Path $keyPath -Parent
if (!(Test-Path -LiteralPath $keyDir)) {
  Write-Error "Failed to create directory '$keyDir' where the key file will be created."
  return
}

if ((Test-Path -LiteralPath $keyPath)) {
  if (!$Force) {
    Write-Error "Path $keyPath already exists. Specify -Force to delete the item and create a new key file."
    return
  }
  Remove-Item -LiteralPath $keyPath
}

ssh-keygen -qo -t "$Type" -b "$Bits" -C "$Comment" -N "$Passphrase" -f "$keyPath" | Out-Null

return $keyPath
