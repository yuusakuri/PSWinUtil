function Get-WUFileCommandDynamicParameter {
    <#
    .SYNOPSIS
    Gets dynamic parameters for a content cmdlet proxy.

    .DESCRIPTION
    Copies provider dynamic parameter definitions from a module-qualified Microsoft content cmdlet into a runtime parameter dictionary.

    .PARAMETER CommandName
    Specifies Get-Content, Set-Content, or Add-Content.

    .PARAMETER BoundParameter
    Specifies the parameters already bound by the proxy function.

    .EXAMPLE
    Get-WUFileCommandDynamicParameter -CommandName 'Get-Content' -BoundParameter $PSBoundParameters

    Returns the provider parameters for Get-Content.

    .INPUTS
    None

    .OUTPUTS
    System.Management.Automation.RuntimeDefinedParameterDictionary
    #>
    [CmdletBinding()]
    [OutputType([System.Management.Automation.RuntimeDefinedParameterDictionary])]
    param(
        [Parameter(Mandatory = $true)]
        [ValidateSet('Get-Content', 'Set-Content', 'Add-Content')]
        [string]$CommandName,

        [Parameter(Mandatory = $true)]
        [System.Collections.IDictionary]$BoundParameter
    )

    $qualifiedName = "Microsoft.PowerShell.Management\$CommandName"
    $targetCommand = $ExecutionContext.InvokeCommand.GetCommand(
        $qualifiedName,
        [System.Management.Automation.CommandTypes]::Cmdlet,
        $BoundParameter
    )
    $dictionary = [System.Management.Automation.RuntimeDefinedParameterDictionary]::new()
    foreach ($parameter in $targetCommand.Parameters.Values) {
        if (-not $parameter.IsDynamic) {
            continue
        }
        $runtimeParameter = [System.Management.Automation.RuntimeDefinedParameter]::new(
            $parameter.Name,
            $parameter.ParameterType,
            $parameter.Attributes
        )
        $dictionary.Add($parameter.Name, $runtimeParameter)
    }

    $dictionary
}
