function Edit-WUSshKey {
    <#
    .SYNOPSIS
    Changes an SSH key passphrase or comment.

    .DESCRIPTION
    Runs ssh-keygen.exe against an existing private key. Passphrase and comment changes use separate parameter sets. OpenSSH Client is not installed automatically.

    .PARAMETER Path
    Specifies the existing private key file path. Wildcards are supported when they resolve to exactly one file.

    .PARAMETER LiteralPath
    Specifies the existing private key file path without wildcard interpretation.

    .PARAMETER NewPassphrase
    Specifies the replacement passphrase. An empty string removes the passphrase.

    .PARAMETER Comment
    Specifies the replacement public key comment.

    .PARAMETER CurrentPassphrase
    Specifies the current passphrase. Use an empty string when the key has no passphrase.

    .EXAMPLE
    Edit-WUSshKey -Path '.\id_rsa' -CurrentPassphrase 'old value' -NewPassphrase 'new value'

    Changes the private key passphrase and returns the key file.

    .EXAMPLE
    Edit-WUSshKey -Path '.\id_rsa' -CurrentPassphrase '' -Comment 'new comment' -WhatIf

    Shows the comment change without running ssh-keygen.exe.

    .EXAMPLE
    Edit-WUSshKey -LiteralPath '.\missing-key' -CurrentPassphrase '' -Comment 'new comment'

    Reports an error because the private key does not exist.

    .OUTPUTS
    System.IO.FileInfo
    #>
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute(
        'PSAvoidUsingPlainTextForPassword',
        '',
        Justification = 'ssh-keygen.exe requires passphrases as command arguments.'
    )]
    [CmdletBinding(
        DefaultParameterSetName = 'PassphrasePath',
        SupportsShouldProcess = $true
    )]
    [OutputType([System.IO.FileInfo])]
    param(
        [Parameter(
            Mandatory = $true,
            ParameterSetName = 'PassphrasePath',
            Position = 0
        )]
        [Parameter(
            Mandatory = $true,
            ParameterSetName = 'CommentPath',
            Position = 0
        )]
        [Alias('KeyPath')]
        [ValidateNotNullOrEmpty()]
        [SupportsWildcards()]
        [string]$Path,

        [Parameter(
            Mandatory = $true,
            ParameterSetName = 'PassphraseLiteralPath'
        )]
        [Parameter(
            Mandatory = $true,
            ParameterSetName = 'CommentLiteralPath'
        )]
        [Alias('PSPath', 'LP')]
        [ValidateNotNullOrEmpty()]
        [string]$LiteralPath,

        [Parameter(Mandatory = $true, ParameterSetName = 'PassphrasePath')]
        [Parameter(Mandatory = $true, ParameterSetName = 'PassphraseLiteralPath')]
        [AllowEmptyString()]
        [string]$NewPassphrase,

        [Parameter(Mandatory = $true, ParameterSetName = 'CommentPath')]
        [Parameter(Mandatory = $true, ParameterSetName = 'CommentLiteralPath')]
        [AllowEmptyString()]
        [string]$Comment,

        [Parameter(Mandatory = $true)]
        [AllowEmptyString()]
        [string]$CurrentPassphrase
    )

    $operationName = if ($PSCmdlet.ParameterSetName -like 'Passphrase*') {
        'Passphrase'
    } else {
        'Comment'
    }
    $resolveParameters = @{
        ParameterSetName = $PSCmdlet.ParameterSetName
        Path = $Path
        LiteralPath = $LiteralPath
        PathSetName = "${operationName}Path"
        LiteralPathSetName = "${operationName}LiteralPath"
        DenyMultiplePaths = $true
    }
    $fullKeyPath = Resolve-WUPathFromParameter @resolveParameters |
        ConvertTo-WUFullPath
    Assert-WUPathProperty -LiteralPath $fullKeyPath -Leaf

    $operationParameters = @{
        KeyPath = $fullKeyPath
        CurrentPassphrase = $CurrentPassphrase
    }
    if ($operationName -eq 'Passphrase') {
        $operationParameters.NewPassphrase = $NewPassphrase
    } else {
        $operationParameters.Comment = $Comment
    }
    $operation = New-WUSshKeyEditOperation @operationParameters
    $sshKeygen = Get-WUSshKeygenCommand

    if (-not $PSCmdlet.ShouldProcess($fullKeyPath, $operation.Action)) {
        return
    }

    Invoke-WUSshKeygen -FilePath $sshKeygen.Source -ArgumentList $operation.ArgumentList

    Get-Item -LiteralPath $fullKeyPath
}
