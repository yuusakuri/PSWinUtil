function New-WUSshKey {
    <#
    .SYNOPSIS
    Creates an SSH key with Windows OpenSSH.

    .DESCRIPTION
    Runs ssh-keygen.exe to create a private and public key. OpenSSH Client is not installed automatically. Existing key files require Force and are removed only after ShouldProcess approves the operation.

    .PARAMETER Path
    Specifies the private key file path.

    .PARAMETER Type
    Specifies the SSH key type. The default value is rsa.

    .PARAMETER Bits
    Specifies the key size passed to ssh-keygen.exe.

    .PARAMETER Comment
    Specifies the public key comment.

    .PARAMETER Passphrase
    Specifies the key passphrase. An empty string creates a key without a passphrase.

    .PARAMETER Force
    Allows existing private and public key files to be replaced.

    .EXAMPLE
    New-WUSshKey -Path "$env:USERPROFILE\.ssh\id_rsa" -Type rsa -Bits 4096

    Creates an RSA key and returns the private key file.

    .EXAMPLE
    New-WUSshKey -Path '.\id_ed25519' -Type ed25519 -WhatIf

    Shows the key generation operation without creating files.

    .EXAMPLE
    New-WUSshKey -Path '.\existing-key'

    Reports an error when existing-key or existing-key.pub already exists and Force is not specified.

    .OUTPUTS
    System.IO.FileInfo
    #>
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute(
        'PSAvoidUsingPlainTextForPassword',
        '',
        Justification = 'ssh-keygen.exe requires passphrases as command arguments.'
    )]
    [CmdletBinding(SupportsShouldProcess = $true)]
    [OutputType([System.IO.FileInfo])]
    param(
        [Parameter(Mandatory = $true, Position = 0)]
        [Alias('KeyPath')]
        [ValidateNotNullOrEmpty()]
        [string]$Path,

        [Parameter()]
        [ValidateSet('dsa', 'ecdsa', 'ecdsa-sk', 'ed25519', 'ed25519-sk', 'rsa')]
        [string]$Type = 'rsa',

        [Parameter()]
        [ValidateRange(256, [int]::MaxValue)]
        [int]$Bits,

        [Parameter()]
        [AllowEmptyString()]
        [string]$Comment = '',

        [Parameter()]
        [AllowEmptyString()]
        [string]$Passphrase = '',

        [Parameter()]
        [switch]$Force
    )

    $sshKeygen = Get-Command -Name 'ssh-keygen.exe' -CommandType Application -ErrorAction Stop |
        Select-Object -First 1
    $keyPath = ConvertTo-WUFullPath -Path $Path
    $publicKeyPath = "$keyPath.pub"
    $keyExists = Test-Path -LiteralPath $keyPath
    $publicKeyExists = Test-Path -LiteralPath $publicKeyPath
    if (($keyExists -or $publicKeyExists) -and -not $Force) {
        throw "An SSH key file already exists. Use Force to replace it: $keyPath"
    }

    if (-not $PSCmdlet.ShouldProcess($keyPath, 'Create SSH key')) {
        return
    }

    $parentPath = Split-Path -Path $keyPath -Parent
    if (-not (Test-Path -LiteralPath $parentPath -PathType Container)) {
        $null = New-Item -Path $parentPath -ItemType Directory -Force
    }
    if ($keyExists) {
        Remove-Item -LiteralPath $keyPath -Force
    }
    if ($publicKeyExists) {
        Remove-Item -LiteralPath $publicKeyPath -Force
    }

    $nativeComment = $Comment
    $nativePassphrase = $Passphrase
    if ($PSVersionTable.PSEdition -eq 'Desktop') {
        if ($nativeComment.Length -eq 0) {
            $nativeComment = '""'
        }
        if ($nativePassphrase.Length -eq 0) {
            $nativePassphrase = '""'
        }
    }

    $arguments = @('-q', '-t', $Type)
    if ($PSBoundParameters.ContainsKey('Bits')) {
        $arguments += @('-b', [string]$Bits)
    }
    $arguments += @('-C', $nativeComment, '-N', $nativePassphrase, '-f', $keyPath)

    $commandOutput = @(& $sshKeygen.Source @arguments 2>&1)
    $exitCode = $LASTEXITCODE
    if ($exitCode -ne 0) {
        $message = @($commandOutput | ForEach-Object { $_.ToString() }) -join [Environment]::NewLine
        throw "ssh-keygen.exe failed with exit code $exitCode.$([Environment]::NewLine)$message"
    }
    if (-not (Test-Path -LiteralPath $keyPath -PathType Leaf)) {
        throw "ssh-keygen.exe did not create the private key: $keyPath"
    }
    if (-not (Test-Path -LiteralPath $publicKeyPath -PathType Leaf)) {
        throw "ssh-keygen.exe did not create the public key: $publicKeyPath"
    }

    Get-Item -LiteralPath $keyPath
}
