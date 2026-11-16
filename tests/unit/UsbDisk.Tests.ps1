BeforeAll {
    . (Join-Path -Path $PSScriptRoot -ChildPath '../UnitTestBootstrap.ps1')

    $script:UsbDiskNumber = 9
    $script:InternalDiskNumber = 8

    function Write-TestFile {
        param(
            [Parameter(Mandatory = $true)]
            [string]$Path,

            [string]$Content = 'content'
        )

        $directory = Split-Path -Path $Path -Parent
        [System.IO.Directory]::CreateDirectory($directory) | Out-Null
        [System.IO.File]::WriteAllText($Path, $Content, [System.Text.UTF8Encoding]::new($false))
    }
}

Describe 'Repair-WUUsbDisk' {
    BeforeEach {
        Mock -CommandName Get-Disk -ModuleName PSWinUtil -MockWith {
            $disks = @(
                [pscustomobject]@{
                    Number = 8
                    FriendlyName = 'Internal Disk'
                    BusType = 'SATA'
                    IsOffline = $true
                    IsReadOnly = $true
                }
                [pscustomobject]@{
                    Number = 9
                    FriendlyName = 'Test Flash Drive'
                    BusType = 'USB'
                    IsOffline = $true
                    IsReadOnly = $true
                }
            )
            if ($PesterBoundParameters.ContainsKey('Number')) {
                return $disks | Where-Object { $_.Number -in $Number }
            }

            $disks
        }
        Mock -CommandName Set-Disk -ModuleName PSWinUtil -MockWith { }
        Mock -CommandName Get-Partition -ModuleName PSWinUtil -MockWith {
            [pscustomobject]@{
                DiskNumber = 9
                PartitionNumber = 1
                DriveLetter = [char]0
                IsOffline = $true
                IsHidden = $false
                Type = 'FAT32'
            }
            [pscustomobject]@{
                DiskNumber = 9
                PartitionNumber = 2
                DriveLetter = [char]0
                IsOffline = $false
                IsHidden = $true
                Type = 'Reserved'
            }
            [pscustomobject]@{
                DiskNumber = 8
                PartitionNumber = 1
                DriveLetter = [char]0
                IsOffline = $true
                IsHidden = $false
                Type = 'IFS'
            }
        }
        Mock -CommandName Set-Partition -ModuleName PSWinUtil -MockWith { }
        Mock -CommandName Add-PartitionAccessPath -ModuleName PSWinUtil -MockWith { }
    }

    It 'brings an offline read-only USB disk online and makes it writable' {
        Repair-WUUsbDisk -DiskNumber $script:UsbDiskNumber

        Should -Invoke -CommandName Set-Disk -ModuleName PSWinUtil -Times 1 -Exactly -ParameterFilter {
            $Number -eq 9 -and $PesterBoundParameters.ContainsKey('IsOffline') -and -not $IsOffline
        }
        Should -Invoke -CommandName Set-Disk -ModuleName PSWinUtil -Times 1 -Exactly -ParameterFilter {
            $Number -eq 9 -and $PesterBoundParameters.ContainsKey('IsReadOnly') -and -not $IsReadOnly
        }
    }

    It 'brings an offline partition online and assigns a drive letter only to the data partition' {
        Repair-WUUsbDisk -DiskNumber $script:UsbDiskNumber

        Should -Invoke -CommandName Set-Partition -ModuleName PSWinUtil -Times 1 -Exactly -ParameterFilter {
            $DiskNumber -eq 9 -and $PartitionNumber -eq 1 -and -not $IsOffline
        }
        Should -Invoke -CommandName Add-PartitionAccessPath -ModuleName PSWinUtil -Times 1 -Exactly
        Should -Invoke -CommandName Add-PartitionAccessPath -ModuleName PSWinUtil -Times 1 -Exactly -ParameterFilter {
            $DiskNumber -eq 9 -and $PartitionNumber -eq 1 -and $AssignDriveLetter
        }
    }

    It 'repairs only USB disks when no disk number is specified' {
        Repair-WUUsbDisk

        Should -Invoke -CommandName Set-Disk -ModuleName PSWinUtil -Times 2 -Exactly
        Should -Invoke -CommandName Set-Disk -ModuleName PSWinUtil -Times 0 -Exactly -ParameterFilter {
            $Number -eq 8
        }
    }

    It 'accepts disks from the pipeline by their number' {
        [pscustomobject]@{ Number = $script:UsbDiskNumber } | Repair-WUUsbDisk

        Should -Invoke -CommandName Set-Disk -ModuleName PSWinUtil -Times 2 -Exactly
    }

    It 'rejects a disk that is not connected through USB' {
        { Repair-WUUsbDisk -DiskNumber $script:InternalDiskNumber -ErrorAction Stop } |
            Should -Throw '*not a USB disk*'

        Should -Invoke -CommandName Set-Disk -ModuleName PSWinUtil -Times 0 -Exactly
        Should -Invoke -CommandName Set-Partition -ModuleName PSWinUtil -Times 0 -Exactly
    }

    It 'changes nothing when previewing the repair' {
        Repair-WUUsbDisk -DiskNumber $script:UsbDiskNumber -WhatIf

        Should -Invoke -CommandName Set-Disk -ModuleName PSWinUtil -Times 0 -Exactly
        Should -Invoke -CommandName Set-Partition -ModuleName PSWinUtil -Times 0 -Exactly
        Should -Invoke -CommandName Add-PartitionAccessPath -ModuleName PSWinUtil -Times 0 -Exactly
    }
}

Describe 'Format-WUUsbDisk' {
    BeforeEach {
        Mock -CommandName Get-Disk -ModuleName PSWinUtil -MockWith {
            $busType = 'USB'
            if ($Number -eq 8) {
                $busType = 'SATA'
            }

            [pscustomobject]@{
                Number = $Number | Select-Object -First 1
                FriendlyName = 'Test Disk'
                BusType = $busType
            }
        }
        Mock -CommandName Initialize-WUUsbDiskVolume -ModuleName PSWinUtil -MockWith { 'E' }
        Mock -CommandName Get-Volume -ModuleName PSWinUtil -MockWith {
            [pscustomobject]@{ DriveLetter = $DriveLetter }
        }
    }

    It 'formats the disk as FAT32 on MBR by default' {
        Format-WUUsbDisk -DiskNumber $script:UsbDiskNumber -Confirm:$false

        Should -Invoke -CommandName Initialize-WUUsbDiskVolume -ModuleName PSWinUtil -Times 1 -Exactly -ParameterFilter {
            $DiskNumber -eq 9 -and $FileSystem -eq 'FAT32' -and $PartitionStyle -eq 'MBR' -and
            -not $DriveLetter -and -not $FileSystemLabel
        }
    }

    It 'passes the requested file system, partition style, drive letter, and label' {
        $formatParameters = @{
            DiskNumber = $script:UsbDiskNumber
            FileSystem = 'NTFS'
            PartitionStyle = 'GPT'
            DriveLetter = 'u'
            FileSystemLabel = 'DATA'
            Confirm = $false
        }
        Format-WUUsbDisk @formatParameters

        Should -Invoke -CommandName Initialize-WUUsbDiskVolume -ModuleName PSWinUtil -Times 1 -Exactly -ParameterFilter {
            $FileSystem -eq 'NTFS' -and $PartitionStyle -eq 'GPT' -and $DriveLetter -eq 'u' -and
            $FileSystemLabel -eq 'DATA'
        }
    }

    It 'returns the formatted volume only when requested' {
        Format-WUUsbDisk -DiskNumber $script:UsbDiskNumber -Confirm:$false | Should -BeNullOrEmpty

        $volume = Format-WUUsbDisk -DiskNumber $script:UsbDiskNumber -PassThru -Confirm:$false
        $volume.DriveLetter | Should -Be 'E'
    }

    It 'rejects a disk that is not connected through USB' {
        { Format-WUUsbDisk -DiskNumber $script:InternalDiskNumber -Confirm:$false } |
            Should -Throw '*not a USB disk*'

        Should -Invoke -CommandName Initialize-WUUsbDiskVolume -ModuleName PSWinUtil -Times 0 -Exactly
    }

    It 'formats the only connected USB disk when no disk number is specified' {
        Mock -CommandName Get-Disk -ModuleName PSWinUtil -MockWith {
            [pscustomobject]@{ Number = 8; FriendlyName = 'Internal Disk'; BusType = 'SATA' }
            [pscustomobject]@{ Number = 9; FriendlyName = 'Test Flash Drive'; BusType = 'USB' }
        }

        Format-WUUsbDisk -Confirm:$false

        Should -Invoke -CommandName Initialize-WUUsbDiskVolume -ModuleName PSWinUtil -Times 1 -Exactly -ParameterFilter {
            $DiskNumber -eq 9
        }
    }

    It 'formats nothing when no disk number is specified and several USB disks are connected' {
        Mock -CommandName Get-Disk -ModuleName PSWinUtil -MockWith {
            [pscustomobject]@{ Number = 7; FriendlyName = 'Backup Drive'; BusType = 'USB' }
            [pscustomobject]@{ Number = 9; FriendlyName = 'Test Flash Drive'; BusType = 'USB' }
        }

        { Format-WUUsbDisk -Confirm:$false } | Should -Throw '*More than one USB disk*7, 9*'

        Should -Invoke -CommandName Initialize-WUUsbDiskVolume -ModuleName PSWinUtil -Times 0 -Exactly
    }

    It 'fails when no disk number is specified and no USB disk is connected' {
        Mock -CommandName Get-Disk -ModuleName PSWinUtil -MockWith {
            [pscustomobject]@{ Number = 8; FriendlyName = 'Internal Disk'; BusType = 'SATA' }
        }

        { Format-WUUsbDisk -Confirm:$false } | Should -Throw '*No USB disk is connected*'

        Should -Invoke -CommandName Initialize-WUUsbDiskVolume -ModuleName PSWinUtil -Times 0 -Exactly
    }

    It 'rejects the disk that contains the running Windows installation' {
        Mock -CommandName Get-Disk -ModuleName PSWinUtil -MockWith {
            [pscustomobject]@{
                Number = $Number | Select-Object -First 1
                FriendlyName = 'Windows To Go'
                BusType = 'USB'
                IsBoot = $true
            }
        }

        { Format-WUUsbDisk -DiskNumber $script:UsbDiskNumber -Confirm:$false } |
            Should -Throw '*running Windows installation*'

        Should -Invoke -CommandName Initialize-WUUsbDiskVolume -ModuleName PSWinUtil -Times 0 -Exactly
    }

    It 'erases nothing when previewing the format' {
        Format-WUUsbDisk -DiskNumber $script:UsbDiskNumber -WhatIf

        Should -Invoke -CommandName Initialize-WUUsbDiskVolume -ModuleName PSWinUtil -Times 0 -Exactly
    }
}

Describe 'Initialize-WUUsbDiskVolume' {
    BeforeEach {
        Mock -CommandName Set-Disk -ModuleName PSWinUtil -MockWith { }
        Mock -CommandName Clear-Disk -ModuleName PSWinUtil -MockWith { }
        Mock -CommandName Initialize-Disk -ModuleName PSWinUtil -MockWith { }
        Mock -CommandName New-Partition -ModuleName PSWinUtil -MockWith {
            [pscustomobject]@{ DriveLetter = [char]'E' }
        }
        Mock -CommandName Format-Volume -ModuleName PSWinUtil -MockWith { }
    }

    It 'erases a partitioned disk and limits a FAT32 partition to 32000 MB' {
        Mock -CommandName Get-Disk -ModuleName PSWinUtil -MockWith {
            [pscustomobject]@{
                Number = 9
                PartitionStyle = 'MBR'
                Size = 64GB
                IsOffline = $false
                IsReadOnly = $true
            }
        }

        $driveLetter = InModuleScope -ModuleName PSWinUtil {
            Initialize-WUUsbDiskVolume -DiskNumber 9 -FileSystem 'FAT32' -PartitionStyle 'MBR'
        }

        $driveLetter | Should -Be 'E'
        Should -Invoke -CommandName Set-Disk -ModuleName PSWinUtil -Times 1 -Exactly -ParameterFilter {
            $PesterBoundParameters.ContainsKey('IsReadOnly') -and -not $IsReadOnly
        }
        Should -Invoke -CommandName Clear-Disk -ModuleName PSWinUtil -Times 1 -Exactly -ParameterFilter {
            $Number -eq 9 -and $RemoveData -and $RemoveOEM
        }
        Should -Invoke -CommandName Initialize-Disk -ModuleName PSWinUtil -Times 0 -Exactly
        Should -Invoke -CommandName New-Partition -ModuleName PSWinUtil -Times 1 -Exactly -ParameterFilter {
            $DiskNumber -eq 9 -and $Size -eq 32000MB -and "$MbrType" -eq 'FAT32' -and
            $AssignDriveLetter -and -not $UseMaximumSize
        }
        Should -Invoke -CommandName Format-Volume -ModuleName PSWinUtil -Times 1 -Exactly -ParameterFilter {
            "$DriveLetter" -eq 'E' -and $FileSystem -eq 'FAT32' -and
            -not $PesterBoundParameters.ContainsKey('NewFileSystemLabel')
        }
    }

    It 'initializes an empty disk with the requested style, drive letter, and label' {
        Mock -CommandName Get-Disk -ModuleName PSWinUtil -MockWith {
            [pscustomobject]@{
                Number = 9
                PartitionStyle = 'RAW'
                Size = 16GB
                IsOffline = $false
                IsReadOnly = $false
            }
        }
        Mock -CommandName New-Partition -ModuleName PSWinUtil -MockWith {
            [pscustomobject]@{ DriveLetter = $DriveLetter }
        }

        InModuleScope -ModuleName PSWinUtil {
            $volumeParameters = @{
                DiskNumber = 9
                FileSystem = 'NTFS'
                PartitionStyle = 'GPT'
                DriveLetter = 'u'
                FileSystemLabel = 'DATA'
            }
            Initialize-WUUsbDiskVolume @volumeParameters
        } | Should -Be 'U'

        Should -Invoke -CommandName Set-Disk -ModuleName PSWinUtil -Times 0 -Exactly
        Should -Invoke -CommandName Clear-Disk -ModuleName PSWinUtil -Times 0 -Exactly
        Should -Invoke -CommandName Initialize-Disk -ModuleName PSWinUtil -Times 1 -Exactly -ParameterFilter {
            $Number -eq 9 -and "$PartitionStyle" -eq 'GPT'
        }
        Should -Invoke -CommandName New-Partition -ModuleName PSWinUtil -Times 1 -Exactly -ParameterFilter {
            $UseMaximumSize -and "$DriveLetter" -eq 'U' -and
            -not $PesterBoundParameters.ContainsKey('MbrType') -and -not $AssignDriveLetter
        }
        Should -Invoke -CommandName Format-Volume -ModuleName PSWinUtil -Times 1 -Exactly -ParameterFilter {
            "$DriveLetter" -eq 'U' -and $FileSystem -eq 'NTFS' -and $NewFileSystemLabel -eq 'DATA'
        }
    }

    It 'fails without formatting when Windows assigns no drive letter' {
        Mock -CommandName Get-Disk -ModuleName PSWinUtil -MockWith {
            [pscustomobject]@{
                Number = 9
                PartitionStyle = 'RAW'
                Size = 16GB
            }
        }
        Mock -CommandName New-Partition -ModuleName PSWinUtil -MockWith {
            [pscustomobject]@{ DriveLetter = [char]0 }
        }

        {
            InModuleScope -ModuleName PSWinUtil {
                Initialize-WUUsbDiskVolume -DiskNumber 9 -FileSystem 'exFAT' -PartitionStyle 'MBR'
            }
        } | Should -Throw '*did not assign a drive letter*'

        Should -Invoke -CommandName Format-Volume -ModuleName PSWinUtil -Times 0 -Exactly
    }
}

Describe 'New-WUBootableUsbDisk' {
    BeforeEach {
        $script:ImagePath = Join-Path -Path $TestDrive -ChildPath 'image.iso'
        $script:IsoRoot = Join-Path -Path $TestDrive -ChildPath ('iso' + [guid]::NewGuid().ToString('N'))
        Write-TestFile -Path $script:ImagePath
        Write-TestFile -Path (Join-Path -Path $script:IsoRoot -ChildPath 'EFI\BOOT\bootx64.efi')

        Mock -CommandName Get-Disk -ModuleName PSWinUtil -MockWith {
            [pscustomobject]@{
                Number = $Number | Select-Object -First 1
                FriendlyName = 'Test Flash Drive'
                BusType = 'USB'
                Size = 16GB
            }
        }
        Mock -CommandName Mount-DiskImage -ModuleName PSWinUtil -MockWith { }
        Mock -CommandName Dismount-DiskImage -ModuleName PSWinUtil -MockWith { }
        Mock -CommandName Get-WUIsoVolume -ModuleName PSWinUtil -MockWith {
            [pscustomobject]@{
                Root = $script:IsoRoot
                FileSystemLabel = 'Ubuntu-Server 24.04 LTS amd64'
            }
        }
        Mock -CommandName Initialize-WUUsbDiskVolume -ModuleName PSWinUtil -MockWith { 'E' }
        Mock -CommandName Copy-WUIsoContent -ModuleName PSWinUtil -MockWith { }
        Mock -CommandName Get-Volume -ModuleName PSWinUtil -MockWith {
            [pscustomobject]@{ DriveLetter = $DriveLetter }
        }
    }

    It 'formats the disk as FAT32 with the ISO label and copies the ISO content' {
        New-WUBootableUsbDisk -ImagePath $script:ImagePath -DiskNumber $script:UsbDiskNumber -Confirm:$false

        Should -Invoke -CommandName Mount-DiskImage -ModuleName PSWinUtil -Times 1 -Exactly -ParameterFilter {
            $ImagePath -eq $script:ImagePath
        }
        Should -Invoke -CommandName Initialize-WUUsbDiskVolume -ModuleName PSWinUtil -Times 1 -Exactly -ParameterFilter {
            $DiskNumber -eq 9 -and $FileSystem -eq 'FAT32' -and $PartitionStyle -eq 'MBR' -and
            $FileSystemLabel -ceq 'UBUNTU-SERV'
        }
        Should -Invoke -CommandName Copy-WUIsoContent -ModuleName PSWinUtil -Times 1 -Exactly -ParameterFilter {
            $SourceRoot -eq $script:IsoRoot -and $DestinationRoot -eq 'E:\'
        }
        Should -Invoke -CommandName Dismount-DiskImage -ModuleName PSWinUtil -Times 1 -Exactly
    }

    It 'writes to the only connected USB disk when no disk number is specified' {
        Mock -CommandName Get-Disk -ModuleName PSWinUtil -MockWith {
            [pscustomobject]@{ Number = 8; FriendlyName = 'Internal Disk'; BusType = 'SATA'; Size = 512GB }
            [pscustomobject]@{ Number = 9; FriendlyName = 'Test Flash Drive'; BusType = 'USB'; Size = 16GB }
        }

        New-WUBootableUsbDisk -ImagePath $script:ImagePath -Confirm:$false

        Should -Invoke -CommandName Initialize-WUUsbDiskVolume -ModuleName PSWinUtil -Times 1 -Exactly -ParameterFilter {
            $DiskNumber -eq 9
        }
    }

    It 'mounts nothing when no disk number is specified and several USB disks are connected' {
        Mock -CommandName Get-Disk -ModuleName PSWinUtil -MockWith {
            [pscustomobject]@{ Number = 7; FriendlyName = 'Backup Drive'; BusType = 'USB'; Size = 1TB }
            [pscustomobject]@{ Number = 9; FriendlyName = 'Test Flash Drive'; BusType = 'USB'; Size = 16GB }
        }

        { New-WUBootableUsbDisk -ImagePath $script:ImagePath -Confirm:$false } |
            Should -Throw '*More than one USB disk*'

        Should -Invoke -CommandName Mount-DiskImage -ModuleName PSWinUtil -Times 0 -Exactly
    }

    It 'returns the written volume when requested' {
        $writeParameters = @{
            ImagePath = $script:ImagePath
            DiskNumber = $script:UsbDiskNumber
            PassThru = $true
            Confirm = $false
        }
        $volume = New-WUBootableUsbDisk @writeParameters

        $volume.DriveLetter | Should -Be 'E'
    }

    It 'keeps the disk and dismounts the image when the ISO has no UEFI boot loader' {
        Remove-Item -LiteralPath (Join-Path -Path $script:IsoRoot -ChildPath 'EFI') -Recurse -Force

        { New-WUBootableUsbDisk -ImagePath $script:ImagePath -DiskNumber $script:UsbDiskNumber -Confirm:$false } |
            Should -Throw '*no UEFI boot loader*'

        Should -Invoke -CommandName Initialize-WUUsbDiskVolume -ModuleName PSWinUtil -Times 0 -Exactly
        Should -Invoke -CommandName Dismount-DiskImage -ModuleName PSWinUtil -Times 1 -Exactly
    }

    It 'dismounts the image when copying fails' {
        Mock -CommandName Copy-WUIsoContent -ModuleName PSWinUtil -MockWith { throw 'copy failed' }

        { New-WUBootableUsbDisk -ImagePath $script:ImagePath -DiskNumber $script:UsbDiskNumber -Confirm:$false } |
            Should -Throw '*copy failed*'

        Should -Invoke -CommandName Dismount-DiskImage -ModuleName PSWinUtil -Times 1 -Exactly
    }

    It 'rejects a file that is not an ISO image' {
        $textPath = Join-Path -Path $TestDrive -ChildPath 'image.txt'
        Write-TestFile -Path $textPath

        { New-WUBootableUsbDisk -ImagePath $textPath -DiskNumber $script:UsbDiskNumber -Confirm:$false } |
            Should -Throw '*not an ISO image file*'

        Should -Invoke -CommandName Mount-DiskImage -ModuleName PSWinUtil -Times 0 -Exactly
    }

    It 'rejects a disk that is not connected through USB' {
        Mock -CommandName Get-Disk -ModuleName PSWinUtil -MockWith {
            [pscustomobject]@{
                Number = $Number | Select-Object -First 1
                FriendlyName = 'Internal Disk'
                BusType = 'NVMe'
            }
        }

        { New-WUBootableUsbDisk -ImagePath $script:ImagePath -DiskNumber $script:InternalDiskNumber -Confirm:$false } |
            Should -Throw '*not a USB disk*'

        Should -Invoke -CommandName Mount-DiskImage -ModuleName PSWinUtil -Times 0 -Exactly
    }

    It 'mounts and erases nothing when previewing the write' {
        New-WUBootableUsbDisk -ImagePath $script:ImagePath -DiskNumber $script:UsbDiskNumber -WhatIf

        Should -Invoke -CommandName Mount-DiskImage -ModuleName PSWinUtil -Times 0 -Exactly
        Should -Invoke -CommandName Initialize-WUUsbDiskVolume -ModuleName PSWinUtil -Times 0 -Exactly
    }
}

Describe 'Assert-WUIsoContent' {
    BeforeEach {
        $script:IsoRoot = Join-Path -Path $TestDrive -ChildPath ('iso' + [guid]::NewGuid().ToString('N'))
        Write-TestFile -Path (Join-Path -Path $script:IsoRoot -ChildPath 'EFI\BOOT\bootx64.efi') -Content 'boot'
    }

    It 'accepts an oversized Windows image because it is split while copying' {
        Write-TestFile -Path (Join-Path -Path $script:IsoRoot -ChildPath 'sources\install.wim') -Content ('x' * 64)

        {
            InModuleScope -ModuleName PSWinUtil -Parameters @{ IsoRoot = $script:IsoRoot } {
                Assert-WUIsoContent -SourceRoot $IsoRoot -Capacity 1MB -MaximumFileLength 16
            }
        } | Should -Not -Throw
    }

    It 'rejects any other file that FAT32 cannot store' {
        Write-TestFile -Path (Join-Path -Path $script:IsoRoot -ChildPath 'casper\filesystem.squashfs') -Content ('x' * 64)

        {
            InModuleScope -ModuleName PSWinUtil -Parameters @{ IsoRoot = $script:IsoRoot } {
                Assert-WUIsoContent -SourceRoot $IsoRoot -Capacity 1MB -MaximumFileLength 16
            }
        } | Should -Throw '*FAT32 cannot store*filesystem.squashfs*'
    }

    It 'rejects content that does not fit on the USB disk' {
        {
            InModuleScope -ModuleName PSWinUtil -Parameters @{ IsoRoot = $script:IsoRoot } {
                Assert-WUIsoContent -SourceRoot $IsoRoot -Capacity 3
            }
        } | Should -Throw '*needs 4 bytes*provides 3 bytes*'
    }
}

Describe 'Copy-WUIsoContent' {
    BeforeEach {
        $testRoot = Join-Path -Path $TestDrive -ChildPath ([guid]::NewGuid().ToString('N'))
        $script:IsoRoot = Join-Path -Path $testRoot -ChildPath 'iso'
        $script:UsbRoot = Join-Path -Path $testRoot -ChildPath 'usb'
        Write-TestFile -Path (Join-Path -Path $script:IsoRoot -ChildPath 'EFI\BOOT\bootx64.efi') -Content 'boot'
        Write-TestFile -Path (Join-Path -Path $script:IsoRoot -ChildPath 'sources\install.wim') -Content ('x' * 64)
        New-Item -Path (Join-Path -Path $script:IsoRoot -ChildPath 'empty') -ItemType Directory | Out-Null
        New-Item -Path $script:UsbRoot -ItemType Directory | Out-Null
        Mock -CommandName Split-WindowsImage -ModuleName PSWinUtil -MockWith { }
    }

    It 'copies files and directories with their relative paths' {
        InModuleScope -ModuleName PSWinUtil -Parameters @{ IsoRoot = $script:IsoRoot; UsbRoot = $script:UsbRoot } {
            Copy-WUIsoContent -SourceRoot $IsoRoot -DestinationRoot $UsbRoot
        }

        $bootLoaderPath = Join-Path -Path $script:UsbRoot -ChildPath 'EFI\BOOT\bootx64.efi'
        [System.IO.File]::ReadAllText($bootLoaderPath) | Should -BeExactly 'boot'
        Join-Path -Path $script:UsbRoot -ChildPath 'sources\install.wim' | Should -Exist
        Join-Path -Path $script:UsbRoot -ChildPath 'empty' | Should -Exist
        Should -Invoke -CommandName Split-WindowsImage -ModuleName PSWinUtil -Times 0 -Exactly
    }

    It 'splits a file that FAT32 cannot store instead of copying it' {
        InModuleScope -ModuleName PSWinUtil -Parameters @{ IsoRoot = $script:IsoRoot; UsbRoot = $script:UsbRoot } {
            Copy-WUIsoContent -SourceRoot $IsoRoot -DestinationRoot $UsbRoot -MaximumFileLength 16
        }

        $expectedImagePath = Join-Path -Path $script:IsoRoot -ChildPath 'sources\install.wim'
        $expectedSplitPath = Join-Path -Path $script:UsbRoot -ChildPath 'sources\install.swm'
        Should -Invoke -CommandName Split-WindowsImage -ModuleName PSWinUtil -Times 1 -Exactly -ParameterFilter {
            $ImagePath -eq $expectedImagePath -and $SplitImagePath -eq $expectedSplitPath
        }
        Join-Path -Path $script:UsbRoot -ChildPath 'sources\install.wim' | Should -Not -Exist
        Join-Path -Path $script:UsbRoot -ChildPath 'EFI\BOOT\bootx64.efi' | Should -Exist
    }
}
