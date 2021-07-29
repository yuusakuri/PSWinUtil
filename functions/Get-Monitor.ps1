function Get-WUMonitor {
    <#
        .SYNOPSIS
        Get Monitor details.

        .DESCRIPTION
        Get the following monitor information:
            resolution
            verticalResolution
            horizontalResolution
            leftTop
            rightBottom
            active
            disconnected
            primary
            bitsPerPixel
            frequency
            orientation
            maximumResolution
            maximumVerticalResolution
            maximumHorizontalResolution
            deviceName
            monitorIndex
            adapter
            deviceId
            deviceKey
            monitorId
            monitorKey
            monitorString
            monitorName
            monitorSerialNumber
            pnpDeviceId
            manufactureWeek
            manufacturerId
            productId
            numericSerialNumber
            edidVersion
            displayGamma
            verticalFrequency
            horizontalFrequency
            imageSize
            maximumImageSize
            supportStandbyMode
            supportSuspendMode
            supportLowPowerMode
            supportDefaultGtf
            digital
            supportedDisplayModes

        .OUTPUTS
        System.Management.Automation.PSCustomObject

        .EXAMPLE
        PS C:\>Get-WUMonitor

        Get details of all monitors.

        .LINK
        Set-WUMonitor
    #>

    [CmdletBinding()]
    param (
    )

    Set-StrictMode -Version 'Latest'

    <# Other ways to get monitor information
        Get-CimInstance -ClassName Win32_VideoController

        Get-CimInstance -ClassName Win32_PnPEntity | Where-Object Service -eq Monitor

        Get-CimInstance -Namespace root\wmi -ClassName WmiMonitorBasicDisplayParams

        MonitorInfoView.exe /sxml $xmlPath

        dumpedid.exe

        Import-WUNuGetPackageAssembly -PackageID 'MonitorDetails' -Install
        (New-Object 'MonitorDetails.Reader').GetMonitorDetails()
    #>

    function Get-WUMonitorFromMultiMonitorTool {
        <#
            .SYNOPSIS
            Get Monitor details from MonitorTool.

            .DESCRIPTION
            Get the following monitor information:
                resolution
                leftTop
                rightBottom
                active
                disconnected
                primary
                colors
                frequency
                orientation
                maximumResolution
                name
                adapter
                deviceId
                deviceKey
                monitorId
                monitorKey
                monitorString
                monitorName
                monitorSerialNumber

            .OUTPUTS
            System.Management.Automation.PSCustomObject

            .EXAMPLE
            PS C:\>Get-WUMonitorFromMultiMonitorTool
        #>

        [CmdletBinding()]
        param (
        )

        try {
            $tempFilePath = ''
            $tempFilePath = New-TemporaryFile -WhatIf:$false |
            Rename-Item -NewName { $_ -replace 'tmp$', 'xml' } -PassThru -WhatIf:$false |
            Select-Object -ExpandProperty FullName
            if (!$tempFilePath) {
                return
            }

            Start-Process 'MultiMonitorTool.exe' -ArgumentList ('/sxml "{0}"' -f ($tempFilePath | Convert-WUString -Type EscapeForPowerShellDoubleQuotation)) -Wait -NoNewWindow -WhatIf:$false

            $monitorXml = $null
            $monitorXml = Select-Xml -LiteralPath $tempFilePath -XPath 'monitors_list/item' | Select-Object -ExpandProperty Node

            if (!$monitorXml) {
                Write-Error "Failed to get monitor information from 'MultiMonitorTool'."
                return
            }

            Write-Debug ($monitorXml | Format-Table | Out-String)

            foreach ($aMonitorXml in $monitorXml) {
                $monitor = New-Object -TypeName psobject

                $aMonitorXml.ChildNodes |
                Where-Object { !($_.Name -eq '#whitespace') } |
                ForEach-Object {
                    $name = Convert-WUString -String $_.Name -Type 'LowerCamelCase'
                    $value = $null
                    if (($_ | Get-Member -MemberType Properties | Where-Object { $_.Name -eq '#text' })) {
                        $value = $_.'#text'
                    }

                    $monitor | Add-Member -MemberType NoteProperty -Name $name -Value $value
                }

                $monitor
            }
        }
        finally {
            $tempFilePath |
            Where-Object { $_ } |
            Where-Object { Test-Path -LiteralPath $_ } |
            Remove-Item -LiteralPath { $_ } -Force -WhatIf:$false
        }
    }

    function Get-WUMonitorFromDumpEdid {
        <#
            .SYNOPSIS
            Get Monitor details from MonitorTool.

            .DESCRIPTION
            Get the following monitor information:
                active
                registryKey
                monitorName
                manufactureWeek
                manufacturerID
                productID
                serialNumberNumeric
                eDIDVersion
                displayGamma
                verticalFrequency
                horizontalFrequency
                imageSize
                maximumImageSize
                maximumResolution
                supportStandbyMode
                supportSuspendMode
                supportLowPowerMode
                supportDefaultGTF
                digital
                supportedDisplayModes

            .OUTPUTS
            System.Management.Automation.PSCustomObject

            .EXAMPLE
            PS C:\>Get-WUMonitorFromDumpEdid
        #>
        [CmdletBinding()]
        param (
        )

        $resultStrings = @()
        $resultStrings += Invoke-Expression 'dumpedid'
        if (!$resultStrings) {
            return
        }

        Write-Debug ('dumpedid:', $resultStrings | Format-Table | Out-String)

        (
            ($resultStrings | Where-Object { ![String]::IsNullOrWhiteSpace($_) }) -join [System.Environment]::NewLine
        ) -split '[*]{65}' |
        Where-Object { ![String]::IsNullOrWhiteSpace($_) } |
        Select-Object -Skip 1 |
        ForEach-Object {
            $aComputerString = $_

            $monitor = New-Object -TypeName psobject
            $displayModes = @()

            $aComputerString -split [System.Environment]::NewLine |
            Where-Object { ![String]::IsNullOrWhiteSpace($_) } |
            ForEach-Object {
                $aLine = $_

                if ($aLine -match '^\s*(?<horizontalResolution>\d+)\s*X\s*(?<verticalResolution>\d+)\s*(?<frequency>\d+)\s*Hz\s*$') {
                    $displayModes += [PSCustomObject]@{
                        horizontalResolution = [int]$Matches['horizontalResolution']
                        verticalResolution   = [int]$Matches['verticalResolution']
                        frequency            = [int]$Matches['frequency']
                    }
                }
                elseif ($aLine -match '^(?<name>Active|Registry Key|Monitor Name|Manufacture Week|ManufacturerID|ProductID|Serial Number \(Numeric\)|EDID Version|Display Gamma|Vertical Frequency|Horizontal Frequency|Image Size|Maximum Image Size|Maximum Resolution|Support Standby Mode|Support Suspend Mode|Support Low-Power Mode|Support Default GTF|Digital)\s*:\s*(?<value>.+)$') {
                    $monitor | Add-Member -MemberType NoteProperty -Name (Convert-WUString -String $Matches['name'] -Type 'LowerCamelCase') -Value $Matches['value']
                }
                elseif ($aLine -match '^(?<name>Supported Display Modes)\s*:\s*$') {
                }
                else {
                    Write-Debug "Line that is unsupported format: $aLine"
                }
            }

            $monitor | Add-Member -MemberType NoteProperty -Name (Convert-WUString -String 'Supported Display Modes' -Type 'LowerCamelCase') -Value $displayModes

            $monitor
        }
    }

    $monitorsFromMultiMonitorTool = @()
    $monitorsFromMultiMonitorTool += Get-WUMonitorFromMultiMonitorTool
    if (!$monitorsFromMultiMonitorTool) {
        return
    }

    $monitorsFromDumpEdid = @()
    $monitorsFromDumpEdid += Get-WUMonitorFromDumpEdid
    if (!$monitorsFromDumpEdid) {
        return
    }

    if ($monitorsFromMultiMonitorTool.Count -ne $monitorsFromDumpEdid.Count) {
        Write-Error "The number of monitors detected does not match."
        return
    }

    for ($i = 0; $i -lt $monitorsFromMultiMonitorTool.Count; $i++) {
        $monitor = New-Object -TypeName psobject
        $aMonitorFromMultiMonitorTool = $monitorsFromMultiMonitorTool[$i]
        $aMonitorFromDumpEdid = $monitorsFromDumpEdid[$i]

        foreach ($aMonitorFromMultiMonitorToolProperty in $aMonitorFromMultiMonitorTool.psobject.Properties) {
            switch ($aMonitorFromMultiMonitorToolProperty.Name) {
                'name' {
                    $monitor | Add-Member -MemberType NoteProperty -Name 'deviceName' -Value $aMonitorFromMultiMonitorToolProperty.Value
                    $monitorIndex = ''
                    if ($aMonitorFromMultiMonitorToolProperty.Value -match '(?<monitorIndex>\d+)') {
                        $monitorIndex = $Matches['monitorIndex']
                    }
                    $monitor | Add-Member -MemberType NoteProperty -Name 'monitorIndex' -Value $monitorIndex
                    break
                }
                'resolution' {
                    $monitor | Add-Member -MemberType NoteProperty -Name $aMonitorFromMultiMonitorToolProperty.Name -Value $aMonitorFromMultiMonitorToolProperty.Value
                    $monitor | Add-Member -MemberType NoteProperty -Name 'verticalResolution' -Value ($aMonitorFromMultiMonitorToolProperty.Value -replace '.+ X ')
                    $monitor | Add-Member -MemberType NoteProperty -Name 'horizontalResolution' -Value ($aMonitorFromMultiMonitorToolProperty.Value -replace ' X .+')
                    break
                }
                'maximumResolution' {
                    $monitor | Add-Member -MemberType NoteProperty -Name $aMonitorFromMultiMonitorToolProperty.Name -Value $aMonitorFromMultiMonitorToolProperty.Value
                    $monitor | Add-Member -MemberType NoteProperty -Name 'maximumVerticalResolution' -Value ($aMonitorFromMultiMonitorToolProperty.Value -replace '.+ X ')
                    $monitor | Add-Member -MemberType NoteProperty -Name 'maximumHorizontalResolution' -Value ($aMonitorFromMultiMonitorToolProperty.Value -replace ' X .+')
                    break
                }
                'colors' {
                    $monitor | Add-Member -MemberType NoteProperty -Name 'bitsPerPixel' -Value $aMonitorFromMultiMonitorToolProperty.Value
                    break
                }
                { $_ -in 'active', 'disconnected', 'primary' } {
                    $monitor | Add-Member -MemberType NoteProperty -Name $aMonitorFromMultiMonitorToolProperty.Name -Value (Convert-StringToBool -String $aMonitorFromMultiMonitorToolProperty.Value)
                    break
                }
                Default {
                    $monitor | Add-Member -MemberType NoteProperty -Name $aMonitorFromMultiMonitorToolProperty.Name -Value $aMonitorFromMultiMonitorToolProperty.Value
                }
            }
        }
        foreach ($aMonitorFromDumpEdidProperty in $aMonitorFromDumpEdid.psobject.Properties) {
            switch ($aMonitorFromDumpEdidProperty.Name) {
                'registryKey' {
                    $monitor | Add-Member -MemberType NoteProperty -Name 'pnpDeviceId' -Value $aMonitorFromDumpEdidProperty.Value
                    break
                }
                { $_ -in 'manufactureWeek', 'displayGamma', 'verticalFrequency', 'horizontalFrequency', 'imageSize', 'maximumImageSize', 'supportedDisplayModes' } {
                    $monitor | Add-Member -MemberType NoteProperty -Name $aMonitorFromDumpEdidProperty.Name -Value $aMonitorFromDumpEdidProperty.Value
                    break
                }
                'manufacturerID' {
                    $monitor | Add-Member -MemberType NoteProperty -Name 'manufacturerId' -Value $aMonitorFromDumpEdidProperty.Value
                    break
                }
                'productID' {
                    $monitor | Add-Member -MemberType NoteProperty -Name 'productId' -Value $aMonitorFromDumpEdidProperty.Value
                }
                'serialNumberNumeric' {
                    $monitor | Add-Member -MemberType NoteProperty -Name 'numericSerialNumber' -Value $aMonitorFromDumpEdidProperty.Value
                    break
                }
                'eDIDVersion' {
                    $monitor | Add-Member -MemberType NoteProperty -Name 'edidVersion' -Value $aMonitorFromDumpEdidProperty.Value
                    break
                }
                'supportDefaultGTF' {
                    $monitor | Add-Member -MemberType NoteProperty -Name 'supportDefaultGtf' -Value (Convert-StringToBool -String $aMonitorFromDumpEdidProperty.Value)
                    break
                }
                { $_ -in 'supportStandbyMode', 'supportSuspendMode', 'supportLowPowerMode', 'digital' } {
                    $monitor | Add-Member -MemberType NoteProperty -Name $aMonitorFromDumpEdidProperty.Name -Value (Convert-StringToBool -String $aMonitorFromDumpEdidProperty.Value)
                    break
                }
            }
        }

        $monitor
    }
}
