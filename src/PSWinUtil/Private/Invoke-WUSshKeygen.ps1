function Invoke-WUSshKeygen {
    <#
    .SYNOPSIS
    Invokes the Windows OpenSSH key generator.

    .DESCRIPTION
    Runs ssh-keygen.exe with the supplied arguments, captures its output, and reports a terminating error when the process returns a nonzero exit code.

    .PARAMETER FilePath
    Specifies the ssh-keygen.exe command path.

    .PARAMETER ArgumentList
    Specifies the arguments passed to ssh-keygen.exe.

    .EXAMPLE
    Invoke-WUSshKeygen -FilePath 'ssh-keygen.exe' -ArgumentList '-q', '-t', 'ed25519'

    Runs ssh-keygen.exe and completes without output when it succeeds.

    .INPUTS
    None

    .OUTPUTS
    None
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$FilePath,

        [Parameter()]
        [AllowEmptyCollection()]
        [string[]]$ArgumentList = @()
    )

    $commandOutput = @(& $FilePath @ArgumentList 2>&1)
    $exitCode = $LASTEXITCODE
    if ($exitCode -eq 0) {
        return
    }

    $message = @($commandOutput | ForEach-Object { $_.ToString() }) -join [Environment]::NewLine
    throw "ssh-keygen.exe failed with exit code $exitCode.$([Environment]::NewLine)$message"
}
