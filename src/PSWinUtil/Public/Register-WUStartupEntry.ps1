function Register-WUStartupEntry {
    <#
    .SYNOPSIS
    Registers a Windows startup entry.

    .DESCRIPTION
    Builds a Windows command line from a fully qualified file system path and optional arguments, then stores it in one or more selected Run registry keys. The command does not start an elevated process.

    .PARAMETER Name
    Specifies the startup entry name.

    .PARAMETER FilePath
    Specifies the executable or script path. Relative file system paths are converted to fully qualified paths.

    .PARAMETER ArgumentList
    Specifies arguments appended to the startup command line.

    .PARAMETER Scope
    Specifies one or more of User and Machine. The default value is User.

    .PARAMETER PassThru
    Returns the stored startup entry.

    .EXAMPLE
    Register-WUStartupEntry -Name 'ExampleApp' -FilePath 'C:\Program Files\Example\app.exe' -ArgumentList '--minimized' -Scope User

    Registers ExampleApp for the current user.

    .EXAMPLE
    Register-WUStartupEntry -Name 'ExampleApp' -FilePath 'C:\Program Files\Example\app.exe' -Scope User, Machine

    Registers ExampleApp for the current user and local machine.

    .INPUTS
    None

    .OUTPUTS
    PSWinUtil.StartupEntry
    #>
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute(
        'PSShouldProcess',
        '',
        Justification = 'Set-WURegistryProperty evaluates ShouldProcess for the delegated change.'
    )]
    [CmdletBinding(SupportsShouldProcess = $true)]
    [OutputType('PSWinUtil.StartupEntry')]
    param(
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$Name,

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$FilePath,

        [Parameter()]
        [AllowEmptyString()]
        [string[]]$ArgumentList = @(),

        [Parameter()]
        [ValidateSet('User', 'Machine')]
        [string[]]$Scope = 'User',

        [Parameter()]
        [switch]$PassThru
    )

    $fullPath = ConvertTo-WUFullPath -Path $FilePath
    Assert-WUPathProperty -LiteralPath $fullPath -Leaf
    $commandLineParts = @(
        ConvertTo-WUWindowsCommandLineArgument -Argument $fullPath -AlwaysQuote
    )
    foreach ($argument in $ArgumentList) {
        $commandLineParts += ConvertTo-WUWindowsCommandLineArgument -Argument $argument
    }
    $commandLine = $commandLineParts -join ' '
    if ($commandLine.Length -gt 260) {
        throw 'A startup command line cannot be longer than 260 characters.'
    }

    $shouldProcessParameters = Select-WUBoundParameter `
        -BoundParameters $PSBoundParameters `
        -Name 'WhatIf', 'Confirm'

    $scopes = @($Scope | Select-Object -Unique)
    foreach ($targetScope in $scopes) {
        $registryPath = switch ($targetScope) {
            'User' { 'Registry::HKEY_CURRENT_USER\Software\Microsoft\Windows\CurrentVersion\Run' }
            'Machine' { 'Registry::HKEY_LOCAL_MACHINE\Software\Microsoft\Windows\CurrentVersion\Run' }
        }
        $setParameters = @{
            Path = $registryPath
            Name = $Name
            Value = $commandLine
            Type = 'String'
        }
        Set-WURegistryProperty @setParameters @shouldProcessParameters
    }

    if ($PassThru) {
        Get-WUStartupEntry -Name $Name -Scope $scopes
    }
}
