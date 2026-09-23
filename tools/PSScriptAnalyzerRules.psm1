function Test-WUControlFlowAst {
    param(
        [Parameter(Mandatory = $true)]
        [System.Management.Automation.Language.Ast]$Ast
    )

    $Ast -is [System.Management.Automation.Language.IfStatementAst] -or
    $Ast -is [System.Management.Automation.Language.ForStatementAst] -or
    $Ast -is [System.Management.Automation.Language.ForEachStatementAst] -or
    $Ast -is [System.Management.Automation.Language.WhileStatementAst] -or
    $Ast -is [System.Management.Automation.Language.DoWhileStatementAst] -or
    $Ast -is [System.Management.Automation.Language.DoUntilStatementAst] -or
    $Ast -is [System.Management.Automation.Language.SwitchStatementAst] -or
    $Ast -is [System.Management.Automation.Language.TryStatementAst]
}

function Get-WUControlFlowDepth {
    param(
        [Parameter(Mandatory = $true)]
        [System.Management.Automation.Language.Ast]$ControlAst,

        [Parameter(Mandatory = $true)]
        [System.Management.Automation.Language.FunctionDefinitionAst]$FunctionAst
    )

    $depth = 0
    $currentAst = $ControlAst
    while ($null -ne $currentAst -and $currentAst -ne $FunctionAst) {
        if ($currentAst -is [System.Management.Automation.Language.FunctionDefinitionAst]) {
            return 0
        }

        if (Test-WUControlFlowAst -Ast $currentAst) {
            $depth++
        }

        $currentAst = $currentAst.Parent
    }

    if ($currentAst -ne $FunctionAst) {
        return 0
    }

    $depth
}

<#
.SYNOPSIS
Warns about backtick line continuations.
.DESCRIPTION
Reports LineContinuation tokens so backticks in strings and comments are ignored.
.OUTPUTS
Microsoft.Windows.PowerShell.ScriptAnalyzer.Generic.DiagnosticRecord[]
#>
function Measure-WUAvoidBacktickContinuation {
    [CmdletBinding()]
    [OutputType([Microsoft.Windows.PowerShell.ScriptAnalyzer.Generic.DiagnosticRecord[]])]
    param(
        [Parameter(Mandatory = $true)]
        [System.Management.Automation.Language.Token[]]$ScriptToken
    )

    foreach ($token in $ScriptToken) {
        if ($token.Kind -ne [System.Management.Automation.Language.TokenKind]::LineContinuation) {
            continue
        }

        [Microsoft.Windows.PowerShell.ScriptAnalyzer.Generic.DiagnosticRecord]@{
            Message = 'Avoid backtick line continuation. Use natural line breaks or splatting.'
            Extent = $token.Extent
            RuleName = $PSCmdlet.MyInvocation.InvocationName
            Severity = 'Warning'
        }
    }
}

<#
.SYNOPSIS
Warns when a function has more than three nested control-flow statements.
.DESCRIPTION
Counts if, loop, switch, and try statements within each function. Nested function
definitions are measured separately.
.OUTPUTS
Microsoft.Windows.PowerShell.ScriptAnalyzer.Generic.DiagnosticRecord[]
#>
function Measure-WUControlFlowNesting {
    [CmdletBinding()]
    [OutputType([Microsoft.Windows.PowerShell.ScriptAnalyzer.Generic.DiagnosticRecord[]])]
    param(
        [Parameter(Mandatory = $true)]
        [System.Management.Automation.Language.ScriptBlockAst]$ScriptBlockAst
    )

    if ($null -ne $ScriptBlockAst.Parent) {
        return
    }

    $functionAsts = $ScriptBlockAst.FindAll({
            param($ast)
            $ast -is [System.Management.Automation.Language.FunctionDefinitionAst]
        }, $true)

    foreach ($functionAst in $functionAsts) {
        $deepestAst = $null
        $maximumDepth = 0
        $controlAsts = $functionAst.Body.FindAll({
                param($ast)
                Test-WUControlFlowAst -Ast $ast
            }, $true)

        foreach ($controlAst in $controlAsts) {
            $depth = Get-WUControlFlowDepth -ControlAst $controlAst -FunctionAst $functionAst
            if ($depth -gt $maximumDepth) {
                $maximumDepth = $depth
                $deepestAst = $controlAst
            }
        }

        if ($maximumDepth -le 3) {
            continue
        }

        [Microsoft.Windows.PowerShell.ScriptAnalyzer.Generic.DiagnosticRecord]@{
            Message = "Function '$($functionAst.Name)' has control-flow nesting depth $maximumDepth (maximum 3). Use guard clauses or extract a function."
            Extent = $deepestAst.Extent
            RuleName = $PSCmdlet.MyInvocation.InvocationName
            Severity = 'Warning'
        }
    }
}

Export-ModuleMember -Function Measure-WUAvoidBacktickContinuation, Measure-WUControlFlowNesting
