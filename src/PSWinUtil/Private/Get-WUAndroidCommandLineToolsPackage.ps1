function Get-WUAndroidCommandLineToolsPackage {
    [CmdletBinding()]
    param()

    $downloadPageUri = 'https://developer.android.com/studio'
    $repositoryUri = 'https://dl.google.com/android/repository'
    $progressPreference = 'SilentlyContinue'
    try {
        $response = Invoke-WebRequest -UseBasicParsing -Uri $downloadPageUri -ErrorAction Stop
    } catch {
        throw "Could not read the Android Studio download page. $($_.Exception.Message)"
    }

    $packageRowPattern = @'
(?is)<tr\b[^>]*>(?:(?!</tr>).)*?(?<Name>commandlinetools-win-\d+_latest\.zip)(?:(?!</tr>).)*?<td\b[^>]*>\s*(?<Sha256>[a-f0-9]{64})\s*</td>(?:(?!</tr>).)*?</tr>
'@
    $packageRows = @([regex]::Matches([string]$response.Content, $packageRowPattern.Trim()))
    if ($packageRows.Count -eq 0) {
        throw 'The Windows Android Command-Line Tools package and checksum were not found on the download page.'
    }

    $packageName = $packageRows[0].Groups['Name'].Value
    [pscustomobject]@{
        Uri = [uri]"$repositoryUri/$packageName"
        FileName = $packageName
        Sha256 = $packageRows[0].Groups['Sha256'].Value.ToUpperInvariant()
    }
}
