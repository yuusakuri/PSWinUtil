function Get-WUSshKeyEditOperation {
    <#
    .SYNOPSIS
    Gets an SSH key edit operation.

    .DESCRIPTION
    Creates the ShouldProcess action and ssh-keygen.exe argument list for a passphrase or comment change.

    .PARAMETER KeyPath
    Specifies the fully qualified private key path.

    .PARAMETER CurrentPassphrase
    Specifies the current private key passphrase.

    .PARAMETER NewPassphrase
    Specifies the replacement passphrase for Passphrase mode.

    .PARAMETER Comment
    Specifies the replacement comment for Comment mode.

    .EXAMPLE
    Get-WUSshKeyEditOperation -KeyPath 'C:\Keys\id_rsa' -CurrentPassphrase '' -Comment 'user@example.com'

    Returns the action and argument list for changing the key comment.

    .INPUTS
    None

    .OUTPUTS
    System.Management.Automation.PSCustomObject
    #>
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute(
        'PSAvoidUsingPlainTextForPassword',
        '',
        Justification = 'ssh-keygen.exe requires passphrases as command arguments.'
    )]
    [CmdletBinding(DefaultParameterSetName = 'Passphrase')]
    [OutputType([System.Management.Automation.PSCustomObject])]
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

    $nativeCurrentPassphrase = ConvertTo-WUSshKeygenArgument -Argument $CurrentPassphrase
    if ($PSCmdlet.ParameterSetName -eq 'Passphrase') {
        $nativeNewPassphrase = ConvertTo-WUSshKeygenArgument -Argument $NewPassphrase
        return [pscustomobject]@{
            Action = 'Change SSH key passphrase'
            ArgumentList = @(
                '-q', '-p', '-P', $nativeCurrentPassphrase,
                '-N', $nativeNewPassphrase, '-f', $KeyPath
            )
        }
    }

    $nativeComment = ConvertTo-WUSshKeygenArgument -Argument $Comment
    return [pscustomobject]@{
        Action = 'Change SSH key comment'
        ArgumentList = @(
            '-q', '-c', '-P', $nativeCurrentPassphrase,
            '-C', $nativeComment, '-f', $KeyPath
        )
    }
}
