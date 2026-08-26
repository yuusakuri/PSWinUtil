function Remove-WUPathEnvironmentVariable {
    <#
    .SYNOPSIS
    Removes paths from the PATH environment variable.

    .DESCRIPTION
    Removes matching paths from one or more Process, User, or Machine PATH values. Matching ignores leading and trailing spaces, a trailing backslash, and character case. Existing nonmatching item text and order are preserved.

    .PARAMETER Path
    Specifies one or more paths to remove. The paths do not need to exist.

    .PARAMETER Scope
    Specifies one or more of Process, User, and Machine. The default value is Process.

    .EXAMPLE
    Remove-WUPathEnvironmentVariable -Path 'C:\Tools\' -Scope User

    Removes C:\Tools from the current user PATH even if the stored path has no trailing backslash.

    .EXAMPLE
    Remove-WUPathEnvironmentVariable -Path 'C:\Tools' -Scope Process, User

    Removes C:\Tools from the current process and current user PATH values.

    .INPUTS
    System.String

    .OUTPUTS
    None
    #>
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute(
        'PSShouldProcess',
        '',
        Justification = 'Set-WUEnvironmentVariable evaluates ShouldProcess for the delegated change.'
    )]
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
        [string[]]$Scope = 'Process'
    )

    begin {
        $pathsToRemove = @()
        $shouldProcessParameters = Select-WUBoundParameter `
            -BoundParameters $PSBoundParameters `
            -Name 'WhatIf', 'Confirm'
    }

    process {
        $pathsToRemove += $Path
    }

    end {
        foreach ($currentScope in $Scope) {
            $target = [System.EnvironmentVariableTarget]$currentScope
            $currentValue = [System.Environment]::GetEnvironmentVariable('Path', $target)
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
                continue
            }

            $updatedValue = Join-WUPathEnvironmentVariable -Path $remainingPaths
            Set-WUEnvironmentVariable `
                -Name 'Path' `
                -Value $updatedValue `
                -Scope $currentScope `
                @shouldProcessParameters
        }
    }
}
