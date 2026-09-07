if ($PSVersionTable.PSEdition -ne 'Desktop') {
    foreach ($commandName in @(Get-WUCommandOverrideName)) {
        $overrideNoun = $commandName -replace '-', ''
        foreach ($functionName in @(
                $commandName
                "Enable-WU${overrideNoun}Override"
                "Disable-WU${overrideNoun}Override"
            )) {
            Microsoft.PowerShell.Management\Remove-Item -LiteralPath "Function:\$functionName" -Force
        }
    }
}
