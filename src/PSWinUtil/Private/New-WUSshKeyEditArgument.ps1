function New-WUSshKeyEditArgument {
    <#
    .SYNOPSIS
    Creates arguments for editing an SSH key.

    .DESCRIPTION
    Creates the ssh-keygen.exe argument values for a passphrase or comment change.

    .PARAMETER KeyPath
    Specifies the fully qualified private key path.

    .PARAMETER CurrentPassphrase
    Specifies the current private key passphrase.

    .PARAMETER NewPassphrase
    Specifies the replacement passphrase.

    .PARAMETER Comment
    Specifies the replacement comment.

    .EXAMPLE
    New-WUSshKeyEditArgument -KeyPath 'C:\Keys\id_rsa' -CurrentPassphrase '' -Comment 'user@example.com'

    Returns the arguments for changing the key comment.

    .INPUTS
    None

    .OUTPUTS
    System.String
    #>
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute(
        'PSAvoidUsingPlainTextForPassword',
        '',
        Justification = 'ssh-keygen.exe requires passphrases as command arguments.'
    )]
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute(
        'PSUseShouldProcessForStateChangingFunctions',
        '',
        Justification = 'The function creates argument values without changing state.'
    )]
    [CmdletBinding(DefaultParameterSetName = 'Passphrase')]
    [OutputType([string])]
    param(
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$KeyPath,

        [Parameter(Mandatory = $true)]
        [AllowEmptyString()]
        [string]$CurrentPassphrase,

        [Parameter(Mandatory = $true, ParameterSetName = 'Passphrase')]
        [AllowEmptyString()]
        [string]$NewPassphrase,

        [Parameter(Mandatory = $true, ParameterSetName = 'Comment')]
        [AllowEmptyString()]
        [string]$Comment
    )

    if ($PSBoundParameters.ContainsKey('NewPassphrase')) {
        '-q', '-p', '-P', $CurrentPassphrase,
        '-N', $NewPassphrase, '-f', $KeyPath
        return
    }

    '-q', '-c', '-P', $CurrentPassphrase,
    '-C', $Comment, '-f', $KeyPath
}
