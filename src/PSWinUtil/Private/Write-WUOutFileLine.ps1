function Write-WUOutFileLine {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [System.IO.TextWriter]$StreamWriter,

        [Parameter()]
        [object[]]$Line,

        [Parameter()]
        [switch]$NoNewline
    )

    foreach ($inputLine in $Line) {
        if ($NoNewline) {
            $StreamWriter.Write([string]$inputLine)
        } else {
            $StreamWriter.WriteLine([string]$inputLine)
        }
    }
}
