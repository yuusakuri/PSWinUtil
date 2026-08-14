function Remove-WUPathEnvironmentVariable {
    <#
    .SYNOPSIS
    Removes paths from the PATH environment variable.

    .DESCRIPTION
    Removes matching paths from the Process, User, or Machine PATH. Matching ignores leading and trailing spaces, a trailing backslash, and character case. Existing nonmatching item text and order are preserved.

    .PARAMETER Path
    Specifies one or more paths to remove. The paths do not need to exist.

    .PARAMETER Scope
    Specifies Process, User, or Machine. The default value is Process.

    .EXAMPLE
    Remove-WUPathEnvironmentVariable -Path 'C:\Tools\' -Scope User

    Removes C:\Tools from the current user PATH even if the stored path has no trailing backslash.

    .INPUTS
    System.String

    .OUTPUTS
    None
    #>
    [CmdletBinding(SupportsShouldProcess = $true)]
    param(
        [Parameter(
            Mandatory = $true,
            Position = 0,
            ValueFromPipeline = $true,
            ValueFromPipelineByPropertyName = $true
        )]
        [ValidateNotNullOrEmpty()]
        [ValidateScript({ -not [string]::IsNullOrWhiteSpace($_) })]
        [string[]]$Path,

        [Parameter()]
        [ValidateSet('Process', 'User', 'Machine')]
        [string]$Scope = 'Process'
    )

    begin {
        $pathsToRemove = @()
    }

    process {
        $pathsToRemove += $Path
    }

    end {
        $currentValue = Get-WUEnvironmentVariableValue -Name 'Path' -Scope $Scope
        $existingPaths = @(Split-WUPathEnvironmentVariable -Value $currentValue)
        $remainingPaths = @()
        $removedPath = $false

        foreach ($existingPath in $existingPaths) {
            $isMatch = $false
            foreach ($pathToRemove in $pathsToRemove) {
                if (Compare-WUPath -ReferencePath $existingPath -DifferencePath $pathToRemove) {
                    $isMatch = $true
                    $removedPath = $true
                    break
                }
            }

            if (-not $isMatch) {
                $remainingPaths += $existingPath
            }
        }

        if (-not $removedPath) {
            return
        }

        $updatedValue = Join-WUPathEnvironmentVariable -Path $remainingPaths
        $targetDescription = "$Scope Path environment variable"
        if ($PSCmdlet.ShouldProcess($targetDescription, 'Remove paths')) {
            Set-WUEnvironmentVariableValue -Name 'Path' -Value $updatedValue -Scope $Scope -Confirm:$false
        }
    }
}
