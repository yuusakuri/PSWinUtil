function Set-WUAutoLogonPassword {
    <#
    .SYNOPSIS
    Stores or removes the Windows auto logon password.

    .DESCRIPTION
    Uses the Local Security Authority policy API declared in the PSWinUtil.Native assembly to store the DefaultPassword private data secret. A null password removes the secret. Secret memory is cleared before it is released.

    .PARAMETER Password
    Specifies the password to store. A null value removes the stored password.

    .EXAMPLE
    Set-WUAutoLogonPassword -Password $securePassword

    Stores the password as the DefaultPassword LSA private data secret.

    .INPUTS
    None

    .OUTPUTS
    None
    #>
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute(
        'PSAvoidUsingPlainTextForPassword',
        '',
        Justification = 'The parameter accepts only SecureString or null after validation.'
    )]
    [CmdletBinding(SupportsShouldProcess = $true)]
    param(
        [Parameter()]
        [AllowNull()]
        [object]$Password
    )

    if ($null -ne $Password -and $Password -isnot [securestring]) {
        throw 'Password must be a SecureString or null.'
    }
    if ($null -ne $Password -and $Password.Length -gt 32766) {
        throw 'Password is too long for an LSA Unicode string.'
    }

    $action = 'Remove auto logon password'
    if ($null -ne $Password) {
        $action = 'Set auto logon password'
    }
    if (-not $PSCmdlet.ShouldProcess('LSA private data: DefaultPassword', $action)) {
        return
    }

    $policyCreateSecret = [uint32]0x00000020
    $secretName = 'DefaultPassword'
    $policyHandle = [IntPtr]::Zero
    $secretNameBuffer = [IntPtr]::Zero
    $passwordBuffer = [IntPtr]::Zero

    try {
        $objectAttributes = [PSWinUtil.NativeMethods.LsaObjectAttributes]::new()
        $objectAttributes.Length = [Runtime.InteropServices.Marshal]::SizeOf(
            [type][PSWinUtil.NativeMethods.LsaObjectAttributes]
        )
        $openStatus = [PSWinUtil.NativeMethods.LsaPolicy]::LsaOpenPolicy(
            [IntPtr]::Zero,
            [ref]$objectAttributes,
            $policyCreateSecret,
            [ref]$policyHandle
        )
        if ($openStatus -ne 0) {
            $win32Error = [PSWinUtil.NativeMethods.LsaPolicy]::LsaNtStatusToWinError($openStatus)
            throw [ComponentModel.Win32Exception]::new([int]$win32Error)
        }

        $secretNameBuffer = [Runtime.InteropServices.Marshal]::StringToHGlobalUni($secretName)
        $secretNameValue = [PSWinUtil.NativeMethods.LsaUnicodeString]::new()
        $secretNameValue.Length = [uint16]($secretName.Length * 2)
        $secretNameValue.MaximumLength = [uint16](($secretName.Length + 1) * 2)
        $secretNameValue.Buffer = $secretNameBuffer

        if ($null -eq $Password) {
            $storeStatus = [PSWinUtil.NativeMethods.LsaPolicy]::LsaStorePrivateDataDelete(
                $policyHandle,
                [ref]$secretNameValue,
                [IntPtr]::Zero
            )
        } else {
            $passwordBuffer = [Runtime.InteropServices.Marshal]::SecureStringToGlobalAllocUnicode($Password)
            $passwordValue = [PSWinUtil.NativeMethods.LsaUnicodeString]::new()
            $passwordValue.Length = [uint16]($Password.Length * 2)
            $passwordValue.MaximumLength = [uint16](($Password.Length + 1) * 2)
            $passwordValue.Buffer = $passwordBuffer
            $storeStatus = [PSWinUtil.NativeMethods.LsaPolicy]::LsaStorePrivateDataValue(
                $policyHandle,
                [ref]$secretNameValue,
                [ref]$passwordValue
            )
        }

        if ($storeStatus -ne 0) {
            $win32Error = [PSWinUtil.NativeMethods.LsaPolicy]::LsaNtStatusToWinError($storeStatus)
            throw [ComponentModel.Win32Exception]::new([int]$win32Error)
        }
    } finally {
        if ($passwordBuffer -ne [IntPtr]::Zero) {
            [Runtime.InteropServices.Marshal]::ZeroFreeGlobalAllocUnicode($passwordBuffer)
        }
        if ($secretNameBuffer -ne [IntPtr]::Zero) {
            [Runtime.InteropServices.Marshal]::FreeHGlobal($secretNameBuffer)
        }
        if ($policyHandle -ne [IntPtr]::Zero) {
            $null = [PSWinUtil.NativeMethods.LsaPolicy]::LsaClose($policyHandle)
        }
    }
}
