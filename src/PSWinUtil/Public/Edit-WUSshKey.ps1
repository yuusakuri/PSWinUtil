function Edit-WUSshKey {
    <#
    .SYNOPSIS
    Changes an SSH key passphrase or comment.

    .DESCRIPTION
    Runs ssh-keygen.exe against an existing private key. Passphrase and comment changes use separate parameter sets. OpenSSH Client is not installed automatically.

    .PARAMETER KeyPath
    Specifies the existing private key file path.

    .PARAMETER NewPassphrase
    Specifies the replacement passphrase. An empty string removes the passphrase.

    .PARAMETER Comment
    Specifies the replacement public key comment.

    .PARAMETER CurrentPassphrase
    Specifies the current passphrase. Use an empty string when the key has no passphrase.

    .EXAMPLE
    Edit-WUSshKey -KeyPath '.\id_rsa' -CurrentPassphrase 'old value' -NewPassphrase 'new value'

    Changes the private key passphrase and returns the key file.

    .EXAMPLE
    Edit-WUSshKey -KeyPath '.\id_rsa' -CurrentPassphrase '' -Comment 'new comment' -WhatIf

    Shows the comment change without running ssh-keygen.exe.

    .EXAMPLE
    Edit-WUSshKey -KeyPath '.\missing-key' -CurrentPassphrase '' -Comment 'new comment'

    Reports an error because the private key does not exist.

    .OUTPUTS
    System.IO.FileInfo
    #>
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute(
        'PSAvoidUsingPlainTextForPassword',
        '',
        Justification = 'ssh-keygen.exe requires passphrases as command arguments.'
    )]
    [CmdletBinding(DefaultParameterSetName = 'Passphrase', SupportsShouldProcess = $true)]
    [OutputType([System.IO.FileInfo])]
    param(
        [Parameter(Mandatory = $true, Position = 0)]
        [Alias('Path')]
        [ValidateNotNullOrEmpty()]
        [string]$KeyPath,

        [Parameter(Mandatory = $true, ParameterSetName = 'Passphrase')]
        [AllowEmptyString()]
        [string]$NewPassphrase,

        [Parameter(Mandatory = $true, ParameterSetName = 'Comment')]
        [AllowEmptyString()]
        [string]$Comment,

        [Parameter(Mandatory = $true)]
        [AllowEmptyString()]
        [string]$CurrentPassphrase
    )

    $fullKeyPath = ConvertTo-WUFullPath -Path $KeyPath
    Assert-WUPathProperty -Path $fullKeyPath -Leaf -Readable -Writable
    $sshKeygen = Get-Command -Name 'ssh-keygen.exe' -CommandType Application -ErrorAction Stop

    $action = 'Change SSH key passphrase'
    $arguments = @('-q', '-p', '-P', $CurrentPassphrase, '-N', $NewPassphrase, '-f', $fullKeyPath)
    if ($PSCmdlet.ParameterSetName -eq 'Comment') {
        $action = 'Change SSH key comment'
        $arguments = @('-q', '-c', '-P', $CurrentPassphrase, '-C', $Comment, '-f', $fullKeyPath)
    }

    if (-not $PSCmdlet.ShouldProcess($fullKeyPath, $action)) {
        return
    }

    $commandOutput = @(& $sshKeygen.Source @arguments 2>&1)
    $exitCode = $LASTEXITCODE
    if ($exitCode -ne 0) {
        $message = @($commandOutput | ForEach-Object { $_.ToString() }) -join [Environment]::NewLine
        throw "ssh-keygen.exe failed with exit code $exitCode.$([Environment]::NewLine)$message"
    }

    Get-Item -LiteralPath $fullKeyPath
}
