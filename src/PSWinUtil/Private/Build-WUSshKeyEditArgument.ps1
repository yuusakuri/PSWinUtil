function Build-WUSshKeyEditArgument {
    <#
    .SYNOPSIS
    Builds arguments for editing an SSH key.

    .DESCRIPTION
    Builds the ssh-keygen.exe argument values for a passphrase or comment change.

    .PARAMETER KeyPath
    Specifies the fully qualified private key path.

    .PARAMETER CurrentPassphrase
    Specifies the current private key passphrase.

    .PARAMETER NewPassphrase
    Specifies the replacement passphrase.

    .PARAMETER Comment
    Specifies the replacement comment.

    .EXAMPLE
    Build-WUSshKeyEditArgument -KeyPath 'C:\Keys\id_rsa' -CurrentPassphrase '' -Comment 'user@example.com'

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
        'PSUseApprovedVerbs',
        '',
        Justification = 'Build accurately describes constructing argument values without executing a command.'
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

    $nativeCurrentPassphrase = ConvertTo-WUNativeCommandArgument -Argument $CurrentPassphrase
    if ($PSCmdlet.ParameterSetName -eq 'Passphrase') {
        $nativeNewPassphrase = ConvertTo-WUNativeCommandArgument -Argument $NewPassphrase
        '-q', '-p', '-P', $nativeCurrentPassphrase,
        '-N', $nativeNewPassphrase, '-f', $KeyPath
        return
    }

    $nativeComment = ConvertTo-WUNativeCommandArgument -Argument $Comment
    '-q', '-c', '-P', $nativeCurrentPassphrase,
    '-C', $nativeComment, '-f', $KeyPath
}
