function Test-WUPathProperty {
    <#
    .SYNOPSIS
    Tests file system path properties.

    .DESCRIPTION
    Expands wildcard Path values and returns a Boolean value for each resolved path. LiteralPath values are tested without wildcard interpretation. A missing path or an unmatched pattern returns false. An existing path can also be tested for item type, readability, and writability.

    .PARAMETER Path
    Specifies one or more file system paths to test. Wildcards are supported.

    .PARAMETER LiteralPath
    Specifies one or more file system paths to test without wildcard interpretation.

    .PARAMETER Leaf
    Tests whether the path is a file.

    .PARAMETER Container
    Tests whether the path is a directory.

    .PARAMETER Readable
    Tests whether the current process can read the file or enumerate the directory.

    .PARAMETER Writable
    Tests whether the current process can open the file for writing or create and remove a temporary file in the directory.

    .EXAMPLE
    Test-WUPathProperty -Path '.\settings.json' -Leaf -Readable

    Returns true when settings.json exists as a readable file.

    .EXAMPLE
    Test-WUPathProperty -Path '.\certificates\*.pem' -Leaf -Readable

    Returns one Boolean value for each matching PEM file.

    .EXAMPLE
    Test-WUPathProperty -Path '.\missing'

    Returns false when the path does not exist.

    .INPUTS
    System.String

    .OUTPUTS
    System.Boolean
    #>
    [CmdletBinding(DefaultParameterSetName = 'Path')]
    [OutputType([bool])]
    param(
        [Parameter(
            Mandatory = $true,
            ParameterSetName = 'Path',
            Position = 0,
            ValueFromPipeline = $true,
            ValueFromPipelineByPropertyName = $true
        )]
        [Alias('FullName')]
        [ValidateNotNullOrEmpty()]
        [SupportsWildcards()]
        [string[]]$Path,

        [Parameter(
            Mandatory = $true,
            ParameterSetName = 'LiteralPath',
            ValueFromPipelineByPropertyName = $true
        )]
        [Alias('PSPath', 'LP')]
        [ValidateNotNullOrEmpty()]
        [string[]]$LiteralPath,

        [Parameter()]
        [switch]$Leaf,

        [Parameter()]
        [switch]$Container,

        [Parameter()]
        [switch]$Readable,

        [Parameter()]
        [switch]$Writable
    )

    begin {
        if ($Leaf -and $Container) {
            throw 'Leaf and Container cannot be specified together.'
        }
    }

    process {
        $selectedPaths = $Path
        if ($PSCmdlet.ParameterSetName -eq 'LiteralPath') {
            $selectedPaths = $LiteralPath
        }

        foreach ($selectedPath in $selectedPaths) {
            $pathsToTest = @($selectedPath)
            if (
                $PSCmdlet.ParameterSetName -eq 'Path' -and
                [System.Management.Automation.WildcardPattern]::ContainsWildcardCharacters($selectedPath)
            ) {
                try {
                    $pathsToTest = @(Resolve-Path -Path $selectedPath -ErrorAction Stop)
                } catch [System.Management.Automation.ItemNotFoundException] {
                    $false
                    continue
                }
            }

            foreach ($pathToTest in $pathsToTest) {
                if ($pathToTest -is [System.Management.Automation.PathInfo]) {
                    if ($pathToTest.Provider.Name -ne 'FileSystem') {
                        throw "The path must use the FileSystem provider: $($pathToTest.Path)"
                    }
                    $fullPath = $pathToTest.ProviderPath
                } else {
                    $fullPath = ConvertTo-WUFullPath -Path $pathToTest
                }

                try {
                    $pathExists = Test-Path -LiteralPath $fullPath -ErrorAction Stop
                } catch {
                    $pathExists = $false
                }
                if (-not $pathExists) {
                    $false
                    continue
                }

                $isLeaf = Test-Path -LiteralPath $fullPath -PathType Leaf
                $isContainer = Test-Path -LiteralPath $fullPath -PathType Container
                if (($Leaf -and -not $isLeaf) -or ($Container -and -not $isContainer)) {
                    $false
                    continue
                }

                if ($Readable) {
                    $readSucceeded = $false
                    try {
                        if ($isLeaf) {
                            $stream = [System.IO.File]::Open(
                                $fullPath,
                                [System.IO.FileMode]::Open,
                                [System.IO.FileAccess]::Read,
                                [System.IO.FileShare]::ReadWrite
                            )
                            $stream.Dispose()
                        } else {
                            $enumerator = [System.IO.Directory]::EnumerateFileSystemEntries($fullPath).GetEnumerator()
                            try {
                                $null = $enumerator.MoveNext()
                            } finally {
                                if ($enumerator -is [System.IDisposable]) {
                                    $enumerator.Dispose()
                                }
                            }
                        }
                        $readSucceeded = $true
                    } catch {
                        $readSucceeded = $false
                    }
                    if (-not $readSucceeded) {
                        $false
                        continue
                    }
                }

                if ($Writable) {
                    $writeSucceeded = $false
                    $probePath = $null
                    try {
                        if ($isLeaf) {
                            $stream = [System.IO.File]::Open(
                                $fullPath,
                                [System.IO.FileMode]::Open,
                                [System.IO.FileAccess]::Write,
                                [System.IO.FileShare]::ReadWrite
                            )
                            $stream.Dispose()
                        } else {
                            $probePath = Join-Path -Path $fullPath -ChildPath ([System.IO.Path]::GetRandomFileName())
                            $stream = [System.IO.File]::Open(
                                $probePath,
                                [System.IO.FileMode]::CreateNew,
                                [System.IO.FileAccess]::Write,
                                [System.IO.FileShare]::None
                            )
                            $stream.Dispose()
                        }
                        $writeSucceeded = $true
                    } catch {
                        $writeSucceeded = $false
                    } finally {
                        if ($null -ne $probePath -and [System.IO.File]::Exists($probePath)) {
                            try {
                                [System.IO.File]::Delete($probePath)
                            } catch {
                                $writeSucceeded = $false
                            }
                        }
                    }
                    if (-not $writeSucceeded) {
                        $false
                        continue
                    }
                }

                $true
            }
        }
    }
}
