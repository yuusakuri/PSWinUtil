BeforeAll {
    Import-Module -Name 'PSScriptAnalyzer' -RequiredVersion '1.25.0'
    $script:RulePath = Join-Path -Path $PSScriptRoot -ChildPath '../../tools/PSScriptAnalyzerRules.psm1'
    $script:RuleSettings = @{
        CustomRulePath = [string[]]@($script:RulePath)
        IncludeDefaultRules = $false
        IncludeRules = @('Measure-WUAvoidBacktickLineContinuation', 'Measure-WUMaximumControlFlowNestingDepth')
    }
}

Describe 'PSWinUtil PSScriptAnalyzer rules' {
    It 'warns for line continuations without matching comments or strings' {
        $source = @'
Get-Item `
    -Path 'sample'
# comment `
$text = 'literal`
continued'
'@

        $findings = @(Invoke-ScriptAnalyzer -ScriptDefinition $source -Settings $script:RuleSettings)

        $findings | Should -HaveCount 1
        $findings[0].RuleName | Should -Match 'Measure-WUAvoidBacktickLineContinuation$'
        $findings[0].Severity.ToString() | Should -Be 'Warning'
        $findings[0].Line | Should -Be 1
    }

    It 'warns when control-flow nesting exceeds three levels' {
        $source = @'
function Test-ThreeLevels {
    if ($true) {
        while ($true) {
            foreach ($item in 1) { $item }
        }
    }
}

function Test-FourLevels {
    if ($true) {
        while ($true) {
            foreach ($item in 1) {
                try { $item } catch { throw }
            }
        }
    }
}
'@

        $findings = @(Invoke-ScriptAnalyzer -ScriptDefinition $source -Settings $script:RuleSettings)

        $findings | Should -HaveCount 1
        $findings[0].RuleName | Should -Match 'Measure-WUMaximumControlFlowNestingDepth$'
        $findings[0].Severity.ToString() | Should -Be 'Warning'
        $findings[0].Message | Should -Match "Test-FourLevels.*depth 4"
    }

    It 'measures nested functions separately' {
        $source = @'
function Test-Outer {
    if ($true) {
        function Test-Inner {
            if ($true) {
                while ($true) {
                    foreach ($item in 1) {
                        try { $item } catch { throw }
                    }
                }
            }
        }
    }
}
'@

        $findings = @(Invoke-ScriptAnalyzer -ScriptDefinition $source -Settings $script:RuleSettings)

        $findings | Should -HaveCount 1
        $findings[0].Message | Should -Match "Test-Inner.*depth 4"
    }
}
