function Edit-WUSshKey {
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
        [Alias('Path', 'LiteralPath')]
        [string]
        $KeyPath,

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

    # Escape when specifying an empty string in the command argument
    $emptyParam = @{
        '' = '""'
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

    $keyFullPath = ConvertTo-WUFullPath -LiteralPath $KeyPath -BasePath '~/.ssh'

    if (!(Assert-WUPathProperty -LiteralPath $keyFullPath -PSProvider FileSystem -PathType Leaf)) {
        return
    }

    $cmd = '& ssh-keygen -qo -P "{0}" -f "{1}"' -f , (Convert-WUString -String $CurrentPassphrase -Type EscapeForPowerShellDoubleQuotation), (Convert-WUString -String $keyFullPath -Type EscapeForPowerShellDoubleQuotation)
    if ($PSBoundParameters.ContainsKey('Comment')) {
        $CommentCmd = '{0} -c -C "{1}"' -f $cmd, (Convert-WUString -String $Comment -Type EscapeForPowerShellDoubleQuotation)

        if ($pscmdlet.ShouldProcess($CommentCmd, 'Execute')) {
            $result = ''
            $result = (Invoke-Expression $CommentCmd | ForEach-Object ToString) -join [System.Environment]::NewLine
            Write-Verbose $result

            if (!$result -or !$result.Contains('The comment in your key file has been changed.')) {
                Write-Error 'Failed to change the comment.'
                return
            }
        }
    }

    if ($PSBoundParameters.ContainsKey('NewPassphrase')) {
        $PassCmd = '{0} -p -N "{1}"' -f $cmd, (Convert-WUString -String $NewPassphrase -Type EscapeForPowerShellDoubleQuotation)

        if ($pscmdlet.ShouldProcess($PassCmd, 'Execute')) {
            $result = ''
            $result = (Invoke-Expression $PassCmd | ForEach-Object ToString) -join [System.Environment]::NewLine
            Write-Verbose $result

            if (!$result -or !$result.Contains('Your identification has been saved with the new passphrase.')) {
                Write-Error 'Failed to change the Passphrase.'
                return
            }
        }
    }

    if ($pscmdlet.ShouldProcess()) {
        return (Get-Item -LiteralPath $keyFullPath)
    }
}
