$PSWinUtil = $PSScriptRoot | Split-Path -Parent

if (!(Test-Path -LiteralPath $PSWinUtil)) {
    Write-Error "Cannot find path '$PSWinUtil' because it does not exist." -Category ObjectNotFound
    return
}

$functionDir = Join-Path $PSWinUtil "functions"
if (!(Test-Path -LiteralPath $functionDir)) {
    Write-Error "Cannot find path '$functionDir' because it does not exist." -Category ObjectNotFound
    return
}

$functionNames = (Get-ChildItem -LiteralPath $functionDir -File -Recurse).BaseName -replace '-', '-WU'

# Rewrite the functions to export
$psdPath = Join-Path $PSWinUtil "PSWinUtil.psd1"
$psdContent = Get-Content -LiteralPath $psdPath -Raw
$publicFunctionNameStr = "'{0}'" -f ($functionNames -join "',`r`n        '")
$newPsdContent = New-Object 'Collections.ArrayList'
$newPsdContent.AddRange(
    @($psdContent -replace 'FunctionsToExport\s+=\s+@\([\s\S]*?\)', ("FunctionsToExport = @(`r`n        {0}`r`n    )" -f $publicFunctionNameStr) -split [System.Environment]::NewLine)
)

# Remove last line break
while ($newPsdContent.Count -ne 0) {
    if ($newPsdContent[$newPsdContent.Count - 1] -ne '') {
        break
    }
    $newPsdContent.RemoveAt(($newPsdContent.Count - 1))
}

[System.IO.File]::WriteAllLines($psdPath, [string[]]$newPsdContent, [System.Text.UTF8Encoding]::new($true))
