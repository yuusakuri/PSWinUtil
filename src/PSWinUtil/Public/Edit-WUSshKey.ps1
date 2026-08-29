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

    $resolveParameters = @{
        ParameterSetName = $PSCmdlet.ParameterSetName
        Path = $Path
        LiteralPath = $LiteralPath
        PathSetName = 'PassphrasePath', 'CommentPath'
        LiteralPathSetName = 'PassphraseLiteralPath', 'CommentLiteralPath'
        DenyMultiplePaths = $true
    }
    $fullKeyPath = Resolve-WUPathFromParameterSet @resolveParameters |
        ConvertTo-WUFullPath
    Assert-WUPathProperty -LiteralPath $fullKeyPath -Leaf

    $argumentParameters = @{
        KeyPath = $fullKeyPath
        CurrentPassphrase = $CurrentPassphrase
    }
    if ($PSBoundParameters.ContainsKey('NewPassphrase')) {
        $argumentParameters.NewPassphrase = $NewPassphrase
        $action = 'Change SSH key passphrase'
    } else {
        $argumentParameters.Comment = $Comment
        $action = 'Change SSH key comment'
    }
    $arguments = @(New-WUSshKeyEditArgument @argumentParameters)

    if (-not $PSCmdlet.ShouldProcess($fullKeyPath, $action)) {
        return
    }

    $commandOutput = @(& 'ssh-keygen.exe' @arguments 2>&1)
    $exitCode = $LASTEXITCODE
    if ($exitCode -ne 0) {
        $message = @($commandOutput | ForEach-Object { $_.ToString() }) -join [Environment]::NewLine
        throw "ssh-keygen.exe failed with exit code $exitCode.$([Environment]::NewLine)$message"
    }

    Get-Item -LiteralPath $fullKeyPath
}
