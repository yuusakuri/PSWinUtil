[CmdletBinding(SupportsShouldProcess,
    DefaultParameterSetName = 'Path')]
param (
    # Specifies a path to one or more locations. Wildcards are permitted.
    [Parameter(Mandatory,
        Position = 0,
        ValueFromPipeline,
        ValueFromPipelineByPropertyName)]
    [ValidateNotNullOrEmpty()]
    [string]
    $Name,

    # Specifies a path to one or more locations. Unlike the Path parameter, the value of the LiteralPath parameter is used exactly as it is typed. No characters are interpreted as wildcards. If the path includes escape characters, enclose it in single quotation marks. Single quotation marks tell Windows PowerShell not to interpret any characters as escape sequences.
    [ValidateNotNullOrEmpty()]
    [ValidateSet('Enable', 'Disable', 'Set', 'Switch', 'Register', 'New', 'Add', 'Remove')]
    [string[]]
    $Verb = @('Enable', 'Disable'),

    [switch]
    $NoScope
)

$PSWinUtil = $PSScriptRoot | Split-Path -Parent
$PSWinUtilRegConfDir = $PSWinUtil | Join-Path -ChildPath "resources/registry"
$PSWinUtilRegFunctionDir = $PSWinUtil | Join-Path -ChildPath "functions/registry"

$writeFiles = @()
$aliasNoun = PSWinUtil\Convert-WUString -String $Name -Type PascalCase
$functionNoun = $aliasNoun -replace '^', 'WU'

$writeFiles += @{
    Path    = $PSWinUtilRegConfDir | Join-Path -ChildPath "$aliasNoun.ps1"
    Content = @"
@{
    $aliasNoun = @{
        LocalMachine = @{
            Keyname   = ''
            Valuename = ''
            Type      = 'REG_DWORD'
            Data      = @{
                Enable  = 1
                Disable = 0
            }
        }
        CurrentUser = @{
            Keyname   = ''
            Valuename = ''
            Type      = 'REG_SZ'
            Data      = @{
                Enable  = 1
                Disable = 0
            }
        }
    }
}
"@
}

foreach ($aVerb in $Verb) {
    $aliasName = "$aVerb-$aliasNoun"
    $functionName = "$aVerb-$functionNoun"

    if ($NoScope) {
        $scopeParamStr = ''
        $scopeArgStr = ''
    }
    else {
        $scopeParamStr = @'
        # Specifies the scope that is affected. The default scope is CurrentUser.
        [ValidateSet('LocalMachine', 'CurrentUser')]
        [string]
        $Scope = 'CurrentUser'

'@
        $scopeArgStr = ' -Scope $Scope'
    }

    $writeFiles += @{
        Path    = $PSWinUtilRegFunctionDir | Join-Path -ChildPath "$aliasName.ps1"
        Content = @"
function $functionName {
    [CmdletBinding(SupportsShouldProcess)]
    param (
$scopeParamStr    )

    Set-StrictMode -Version 'Latest'
    `$registryHash = Get-WURegistryHash
    if (!`$registryHash) {
        return
    }

    Set-WURegistryFromHash -RegistryHash `$registryHash$scopeArgStr -DataKey `$MyInvocation.MyCommand.Verb
}
"@
    }
}

foreach ($aWriteFile in $writeFiles) {
    $aPath = $aWriteFile.Path
    $aContent = $aWriteFile.Content

    if ((Test-Path -LiteralPath $aPath)) {
        Write-Error "Path '$aPath' already exists."
        continue
    }

    $shouldProcessTarget = @(
        "Path: $aPath"
        "Content: $aContent"
    ) -join [System.Environment]::NewLine
    if ($PSCmdlet.ShouldProcess($shouldProcessTarget, "Write content")) {
        [System.IO.File]::WriteAllLines($aPath, [string[]]$aContent, [System.Text.UTF8Encoding]::new($true))
    }
}
