@{
    Severity = @(
        'Error'
        'Warning'
    )

    IncludeDefaultRules = $true

    CustomRulePath = @('./tools/PSScriptAnalyzerRules.psm1')

    ExcludeRules = @(
        'PSUseBOMForUnicodeEncodedFile'
    )
}
