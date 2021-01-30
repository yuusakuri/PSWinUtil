$script:PSWinUtil = Convert-Path "$PSScriptRoot/.."

if (!(Test-Path -LiteralPath $script:PSWinUtil)) {
    Write-Error "Cannot find path '$script:PSWinUtil' because it does not exist." -Category ObjectNotFound
    return
}

$functionDir = "$script:PSWinUtil/functions"
if (!(Test-Path -LiteralPath $functionDir)) {
    Write-Error "Cannot find path '$functionDir' because it does not exist." -Category ObjectNotFound
    return
}

$functionNames = (Get-ChildItem -LiteralPath $functionDir -File -Recurse).BaseName

# Rewrite the functions to export
$psdPath = "$script:PSWinUtil/PSWinUtil.psd1"
$psdContent = Get-Content -LiteralPath $psdPath -Raw
$publicFunctionNameStr = "'{0}'" -f ($functionNames -join "',`r`n        '")
$newPsdContent = New-Object 'Collections.ArrayList'
$newPsdContent.AddRange(
    @($psdContent -replace 'FunctionsToExport\s+=\s+@\([\s\S]*?\)', ("FunctionsToExport = @(`r`n        {0}`r`n    )" -f $publicFunctionNameStr) -split [System.Environment]::NewLine)
)

# Remove last line break
while ($newPsdContent.Count -ne 0) {
    if ($newPsdContent[$newPsdContent.Count - 1] -eq '') {
        $newPsdContent.RemoveAt(($newPsdContent.Count - 1))
    }
    else {
        break
    }
}

[System.IO.File]::WriteAllLines($psdPath, [string[]]$newPsdContent, [System.Text.UTF8Encoding]::new($true))
