function Add-WUEnvironmentVariableFromFile {
    <#
        .SYNOPSIS
        Add environment variables from PowerShell script file or object.

        .DESCRIPTION
        Add environment variables from PowerShell script file or object. The supported formats are:

        - PowerShell Hashtable (System.Collections.Hashtable) objects
        - PowerShell script file that returns Hashtable objects

        .EXAMPLE
        PS C:\>@{ NAME = 'Value' } | Add-WUEnvironmentVariableFromFile -Scope 'Process'

        In this example, `NAME`: `Value` is added to the process scope environment variable.

        .EXAMPLE
        PS C:\>Add-WUEnvironmentVariableFromFile -FilePath 'Powershell script path that returns a hashtable' -Scope 'Process'

        In this example, Adds environment variables from the hashtables returned by running the specified powershell script.
    #>

    [CmdletBinding(DefaultParameterSetName = 'Hashtable',
        SupportsShouldProcess)]
    param (
        # Specifies PowerShell script paths that return a hashtable. Wildcards are not permitted.
        [Parameter(Mandatory,
            Position = 0,
            ParameterSetName = 'FilePath',
            ValueFromPipelineByPropertyName)]
        [Alias('LiteralPath')]
        [ValidateNotNullOrEmpty()]
        [string[]]
        $FilePath,

        # Specifies hashtable.
        [Parameter(Mandatory,
            Position = 0,
            ParameterSetName = 'Hashtable',
            ValueFromPipeline,
            ValueFromPipelineByPropertyName)]
        [ValidateNotNullOrEmpty()]
        [hashtable[]]
        $Hashtable,

        # Specifies the location where an environment variable. The default Scope is Process. The Process is included even if you do not specify it.
        [ValidateSet('LocalMachine', 'CurrentUser', 'Process')]
        [string[]]
        $Scope = 'Process'
    )

    begin {
        Set-StrictMode -Version 'Latest'

        $Scope = $Scope + 'Process' | Select-Object -Unique

        if ($psCmdlet.ParameterSetName -eq 'FilePath') {
            $removeParamKeys = @(
                'FilePath'
                'Hashtable'
                'Scope'
            )
            $paramsOfAddWUEnvironmentVariableFromFile = @{  } + $PSBoundParameters
            @() + $paramsOfAddWUEnvironmentVariableFromFile.Keys | `
                Where-Object { $_ -in $removeParamKeys } | `
                ForEach-Object { $paramsOfAddWUEnvironmentVariableFromFile.Remove($_) }
        }
        elseif ($psCmdlet.ParameterSetName -eq 'Hashtable') {
            $scopeParams = @{
                LocalMachine = 'ForComputer'
                CurrentUser  = 'ForUser'
                Process      = 'ForProcess'
            }
        }
    }
    process {
        if ($psCmdlet.ParameterSetName -eq 'FilePath') {
            foreach ($aPath in $FilePath) {
                if (!(Assert-WUPathProperty -LiteralPath $aPath -PSProvider FileSystem -PathType Leaf)) {
                    continue
                }

                $hashtables = @{}
                $isPathPSScript = Test-WUPSScript -LiteralPath $aPath -AllowedExtension '.ps1'
                if ($isPathPSScript) {
                    try {
                        $hashtables += . $aPath
                    }
                    catch {
                    }

                    if ($hashTables.Keys.Count -eq 0) {
                        Write-Error "Could not get hashtables from powershell script '$aPath'." -ErrorAction $ErrorActionPreference
                        continue
                    }
                }
                else {
                    Write-Error "File '$aPath' is not supported." -ErrorAction $ErrorActionPreference
                    continue
                }

                Add-WUEnvironmentVariableFromFile -Hashtable $hashtables @paramsOfAddWUEnvironmentVariableFromFile
            }
        }
        elseif ($psCmdlet.ParameterSetName -eq 'Hashtable') {
            foreach ($aHashtable in $Hashtable) {
                foreach ($aName in [string[]]$aHashtable.Keys) {
                    if ($null -eq $aHashtable.$aName) {
                        $value = ''
                    }
                    elseif ($aHashtable.$aName.GetType().Name -eq 'String') {
                        $value = $aHashtable.$aName
                    }
                    else {
                        Write-Error "The value of '$aName' environment variable must be of type 'System.String'."
                        continue
                    }

                    foreach ($aScope in $Scope) {
                        $paramsOfSetCEnvironmentVariable = @{
                            Name                 = $aName
                            Value                = $value
                            $scopeParams.$aScope = $true
                            Force                = $true
                        }
                        Set-CEnvironmentVariable @paramsOfSetCEnvironmentVariable
                    }
                }
            }
        }
    }
}
