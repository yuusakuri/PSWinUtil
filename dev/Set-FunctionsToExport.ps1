$script:PSWinUtil = Convert-Path "$PSScriptRoot/.."

if (!(Test-Path -LiteralPath $script:PSWinUtil)) {
    Write-Error "Cannot find path '$script:PSWinUtil' because it does not exist." -Category ObjectNotFound
    return
}

$functionDir = "$script:PSWinUtil/Functions"
if (!(Test-Path -LiteralPath $functionDir)) {
    Write-Error "Cannot find path '$functionDir' because it does not exist." -Category ObjectNotFound
    return
}

# 関数名を取得
$functionNames = (Get-ChildItem -LiteralPath $functionDir -File -Recurse).BaseName

# エクスポートする関数を書き換え
$psdPath = "$script:PSWinUtil/PSWinUtil.psd1"
$psdContent = Get-Content -LiteralPath $psdPath -Raw
$publicFunctionNameStr = "'{0}'" -f ($functionNames -join "',`n    '")
$newPsdContent = $psdContent -replace 'FunctionsToExport\s+=\s+@\([\s\S]*?\)', ("FunctionsToExport = @(`n    {0}`n  )" -f $publicFunctionNameStr)

[System.IO.File]::WriteAllLines($psdPath, [string[]]$newPsdContent, [System.Text.UTF8Encoding]::new($true))
