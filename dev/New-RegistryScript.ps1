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

$script:PSWinUtil = Convert-Path "$PSScriptRoot/.."

$Name = ConvertTo-WUPascalCase -String $Name
$registryFiles = @()
$registryFiles += @{}
$registryFiles[0].Path = "$script:PSWinUtil/resources/registry/$Name.ps1"
$registryFiles[0].Content = @"
@{
    $Name = @{
        LocalMachine = @{
            KeyName   = ''
            ValueName = ''
            Type      = 'REG_DWORD'
            Data      = @{
                Enable  = 1
                Disable = 0
            }
        }
        CurrentUser = @{
            KeyName   = ''
            ValueName = ''
            Type      = 'REG_SZ'
            Data      = @{
                Enable  = 1
                Disable = 0
            }
        }
    }
}
"@

for ($i = 0; $i -lt $Verb.Count; $i++) {
    $registryFiles += @{}
    $registryFiles[$i + 1].Path = "$script:PSWinUtil/functions/registry/{0}-WU$Name.ps1" -f $Verb[$i]
    $scopeParamStr = @'
    # Specifies the scope that is affected. The default scope is CurrentUser.
    [ValidateSet('LocalMachine', 'CurrentUser')]
    [string]
    $Scope = 'CurrentUser'

'@

    $scopeArgStr = ' -Scope $Scope'

    if ($NoScope) {
        $scopeParamStr = ''
        $scopeArgStr = ''
    }

    $registryFiles[$i + 1].Content = @"
<#
    .DESCRIPTION
    This cmdlet works with registry.
#>

[CmdletBinding(SupportsShouldProcess)]
param (
$scopeParamStr)

Set-StrictMode -Version 'Latest'
`$registryHash = Get-WURegistryHash
if (!`$registryHash) {
    return
}

Set-WURegistryFromHash -RegistryHash `$registryHash$scopeArgStr -DataKey `$MyInvocation.MyCommand.Verb
"@
}

foreach ($registryFile in $registryFiles) {
    $aPath = $registryFile.Path
    $aContent = $registryFile.Content

    if ((Test-Path -LiteralPath $aPath)) {
        Write-Error "Path '$aPath' already exists."
        continue
    }

    [System.IO.File]::WriteAllLines($aPath, $aContent, (New-Object System.Text.UTF8Encoding $true))
}
