function New-WUSshKey {
    <#
        .SYNOPSIS
        Create SSH key using ssh-keygen.

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

    begin {
        Set-StrictMode -Version 'Latest'

        # Escape when specifying an empty string in the command argument
        $emptyParam = @{
            '' = '""'
        }
        if ($emptyParam.ContainsKey($Comment)) {
            $Comment = $emptyParam.$Comment
        }
        if ($emptyParam.ContainsKey($Passphrase)) {
            $Passphrase = $emptyParam.$Passphrase
        }
        elseif ($Passphrase.Length -lt 5) {
            Write-Error 'Passphrase must be a minimum of 5 characters.'
            return
        }
    }

    process {
        # Get the full path of the key file and create the parent directory
        $KeyFullPath = ConvertTo-WUFullPath -LiteralPath $KeyPath -BasePath '~/.ssh' -Parents
        if (!$KeyFullPath) {
            return
        }

        # Test the parent directory of the key file
        $keyParentPath = Split-Path $KeyFullPath -Parent
        if (!$keyParentPath) {
            Write-Error "Failed to get the parent directory of path '$KeyFullPath'."
            return
        }
        if (!(Test-Path -LiteralPath $keyParentPath) -or !(Assert-WUPathProperty -LiteralPath $keyParentPath -PSProvider FileSystem -PathType Container)) {
            return
        }

        if ((Test-Path -LiteralPath $KeyFullPath)) {
            # If the key path already exists
            if (!$Force) {
                Write-Error "Path '$KeyFullPath' already exists. Specify -Force to delete the item and create a new key file."
                return
            }

            try {
                Remove-Item -LiteralPath $KeyFullPath -Force -ErrorAction Stop
            }
            catch {
                Write-Error $_ -ErrorAction $ErrorActionPreference
                return
            }
        }

        $cmd = '& ssh-keygen -qo'
        $cmd = '{0} -t "{1}" -b "{2}" -C "{3}" -N "{4}" -f "{5}"' -f $cmd, $Type, $Bits, (Convert-WUString -String $Comment -Type EscapeForPowerShellDoubleQuotation), (Convert-WUString -String $Passphrase -Type EscapeForPowerShellDoubleQuotation), (Convert-WUString -String $KeyFullPath -Type EscapeForPowerShellDoubleQuotation)

        if ($pscmdlet.ShouldProcess($cmd, 'Execute')) {
            $result = (Invoke-Expression $cmd | ForEach-Object ToString) -join [System.Environment]::NewLine
            Write-Verbose $result

            if (!(Test-Path -LiteralPath $KeyFullPath)) {
                Write-Error 'Failed to create ssh key.'
                return
            }

            return (Get-Item -LiteralPath $keyFullPath)
        }
    }
}
