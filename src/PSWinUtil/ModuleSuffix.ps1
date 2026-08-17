if ($PSVersionTable.PSEdition -ne 'Desktop') {
    foreach ($commandName in @('Get-Content', 'Set-Content', 'Add-Content', 'Out-File')) {
        Microsoft.PowerShell.Management\Remove-Item `
            -LiteralPath "Function:\$commandName" `
            -Force
    }
}
