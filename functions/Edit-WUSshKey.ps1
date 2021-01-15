<#
    .SYNOPSIS
    Edit SSH key.

    .DESCRIPTION
    Edit an ssh key using ssh-keygen. This cmdlet use the new OpenSSH format rather than the more compatible PEM format. The new format has increased resistance to brute-force password cracking but is not supported by versions of OpenSSH prior to 6.5.

    .OUTPUTS
    System.String

    Returns the key file path if the change was successful.

    .EXAMPLE
    PS C:\>Edit-WUSshKey -Path test_rsa -NewPassphrase '' -CurrentPassphrase 'aaaaaa'

    In this example, change the key file passphrase from 'aaaaaa' to none.

    .EXAMPLE
    PS C:\>Edit-WUSshKey -Path test_rsa -Comment 'comment' -CurrentPassphrase ''

    In this example, change the comment in the key file with an empty passphrase to 'comment'.

    .LINK
    New-WUSshKey
#>

[CmdletBinding(SupportsShouldProcess)]
param (
    # Specify the location of the key file to be created, relative path from '~/.ssh' or absolute path.
    [Parameter(Mandatory,
        Position = 0,
        ValueFromPipeline,
        ValueFromPipelineByPropertyName)]
    [ValidateNotNullOrEmpty()]
    [string]
    $Path,

    # Specify a new passphrase.
    [string]
    $NewPassphrase,

    # Specify the current passphrase.
    [string]
    $CurrentPassphrase,

    # Specify a new comment.
    [string]
    $Comment
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
if ($emptyParam.ContainsKey($CurrentPassphrase)) {
    $CurrentPassphrase = $emptyParam.$CurrentPassphrase
}
if ($emptyParam.ContainsKey($NewPassphrase)) {
    $NewPassphrase = $emptyParam.$NewPassphrase
}
elseif ($NewPassphrase.Length -lt 5) {
    Write-Error 'Passphrase must be a minimum of 5 characters.'
    return
}

$keyPath = Resolve-WUFullPath -LiteralPath $Path -BasePath '~/.ssh'

if (!(Test-Path -LiteralPath $keyPath)) {
    Write-Error "Cannot find path '$keyPath' because it does not exist." -Category ObjectNotFound
    return
}

if ($PSBoundParameters.ContainsKey('Comment')) {
    $resultMess = ssh-keygen -qo -c -C "$Comment" -P "$CurrentPassphrase" -f "$keyPath"

    if (!$resultMess -or !$resultMess.Contains('The comment in your key file has been changed.')) {
        Write-Error 'Failed to change the comment.'
        return
    }
}

if ($PSBoundParameters.ContainsKey('NewPassphrase')) {
    $resultMess = ssh-keygen -qo -p -P "$CurrentPassphrase" -N "$NewPassphrase" -f "$keyPath"

    if (!$resultMess -or !$resultMess.Contains('Your identification has been saved with the new passphrase.')) {
        Write-Error 'Failed to change the Passphrase.'
        return
    }
}

return $keyPath
