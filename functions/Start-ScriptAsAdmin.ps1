﻿function Start-WUScriptAsAdmin {
    <#
        .SYNOPSIS
        Launch a new prompt with administrative privileges and run a script.

        .DESCRIPTION
        You can pass arguments that contain complex objects to the script file.

        .OUTPUTS
        None, System.Diagnostics.Process

        This cmdlet generates a System.Diagnostics.Process object, if you specify the PassThru parameter. Otherwise, this cmdlet does not return any output.

        .EXAMPLE
        PS C:\> if (!(Test-CAdminPrivilege)) {
                    Start-WUScriptAsAdmin -Path $PSCommandPath -Arguments $PSBoundParameters -NoLogo -NoExit -ExecutionPolicy  Bypass
                    exit
                }

        In this example, if you do not have administrator privileges when you run the script file, you will switch to a new prompt with administrator privileges and run the script file from scratch.
        The launched prompt does not display the logo, the execution policy is set to Bypass, and it does not close when the script finishes executing.

        .LINK
        Start-Process
    #>

    [CmdletBinding(DefaultParameterSetName = 'Path')]
    param (
        # Specifies a Powershell script path. The value of this parameter is used exactly as it is typed. No characters are interpreted as wildcards. If the path includes escape characters, enclose it in single quotation marks. Single quotation marks tell Windows PowerShell not to interpret any characters as escape sequences.
        [Parameter(Mandatory,
            Position = 0,
            ParameterSetName = 'Path',
            ValueFromPipeline,
            ValueFromPipelineByPropertyName)]
        [ValidateNotNullOrEmpty()]
        [SupportsWildcards()]
        [Alias('PSPath')]
        [Alias('LiteralPath')]
        [Alias('Path')]
        [string]
        $PSScriptPath,

        # Specifies the hash table of the script file arguments. See example.
        # For more information, see about_Splatting (https://docs.microsoft.com/en-us/powershell/module/microsoft.powershell.core/about/about_splatting).
        [hashtable]
        $Arguments,

        # Hides the copyright banner at startup.
        [switch]
        $NoLogo,

        # Does not exit after running startup commands.
        [switch]
        $NoExit,

        # Does not load the PowerShell profile.
        [switch]
        $NoProfile,

        # NonInteractive
        [switch]
        $NonInteractive,

        # Sets the default execution policy for the current session and saves it in the $env:PSExecutionPolicyPreference environment variable. This parameter does not change the PowerShell execution policy that is set in the registry. For information about PowerShell execution policies, including a list of valid values, see about_Execution_Policies (https://docs.microsoft.com/en-us/powershell/module/microsoft.powershell.core/about/about_execution_policies).
        [ValidateSet('AllSigned', 'Bypass', 'Default', 'RemoteSigned', 'Restricted', 'Undefined', 'Unrestricted')]
        [string]
        $ExecutionPolicy,

        # Indicates that this cmdlet waits for the specified process and its descendants to complete before accepting more input. This parameter suppresses the command prompt or retains the window until the processes finish.
        [switch]
        $Wait,

        # Returns a process object for each process that the cmdlet started. By default, this cmdlet does not generate any output.
        [switch]
        $PassThru,

        # Sets the window style for the session. Valid values are Normal, Minimized, Maximized and Hidden.
        [ValidateSet('Normal', 'Minimized', 'Maximized', 'Hidden')]
        [string]
        $WindowStyle = 'Normal'
    )

    Set-StrictMode -Version 'Latest'

    if (!(Assert-WUPSScript -LiteralPath $PSScriptPath -AllowedExtension '.ps1')) {
        continue
    }

    $PSScriptPath = $psCmdlet.SessionState.Path.GetUnresolvedProviderPathFromPSPath($PSScriptPath)

    $powershellArgs = @()
    $startProcessArgs = @{}

    if ($NoLogo) {
        $powershellArgs += '-NoLogo'
    }
    if ($NoExit) {
        $powershellArgs += '-NoExit'
    }
    if ($NoProfile) {
        $powershellArgs += '-NoProfile'
    }
    if ($NonInteractive) {
        $powershellArgs += '-NonInteractive'
    }
    if ($ExecutionPolicy) {
        $powershellArgs += "-ExecutionPolicy $ExecutionPolicy"
    }
    if ($Wait) {
        $startProcessArgs.Add('Wait', $true)
    }
    if ($PassThru) {
        $startProcessArgs.Add('PassThru', $true)
    }
    if ($WindowStyle) {
        $powershellArgs += "-WindowStyle $WindowStyle"
        $startProcessArgs.Add('WindowStyle', $WindowStyle)
    }

    $escapedScriptPath = $PSScriptPath | Convert-WUString -Type EscapeForPowerShellDoubleQuotation

    if ($Arguments) {
        $tempFilePath = ''
        $tempFilePath = New-TemporaryFile |
        Rename-Item -NewName { $_ -replace 'tmp$', 'xml' } -PassThru |
        Select-Object -ExpandProperty FullName
        if (!$tempFilePath) {
            return
        }

        $Arguments | Export-Clixml -LiteralPath $tempFilePath -Force

        $powershellArgs += '-Command & {{ $argments = @{{  }} + (Import-Clixml -LiteralPath "{0}");  Write-Output "{0}" | Where-Object {{ Test-Path -LiteralPath $_ }} | Remove-Item -LiteralPath {{ $_ }} -Recurse -Force; . "{1}" @argments }}' -f `
        ($tempFilePath | Convert-WUString -Type EscapeForPowerShellDoubleQuotation),
        $escapedScriptPath
    }
    else {
        $powershellArgs += '-Command & {{ . "{0}" }}' -f $escapedScriptPath
    }

    Write-Debug (@(@('PowerShell argments:') + $powershellArgs) -join [System.Environment]::NewLine)
    Start-Process (Get-Process -Id $PID).Path -ArgumentList $powershellArgs @startProcessArgs -Verb RunAs
}
