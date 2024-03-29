﻿function Get-WUChassisType {
    <#
        .SYNOPSIS
        Get whether the computer is Desktop, Tablet, or Server from ChassisTypes.

        .DESCRIPTION
        Get whether the computer is Desktop, Tablet, or Server from ChassisTypes. Be sure to test in your own environment.

        .OUTPUTS
        System.String

        Returns this computer type. The range of values is 'Desktop', 'Laptop', 'Tablet' or 'Server'.

        .EXAMPLE
        PS C:\>Get-ChassisType

        Returns this computer Chassis type.
    #>

    [CmdletBinding()]
    param (
    )

    Set-StrictMode -Version 'Latest'

    [int[]]$chassisType = Get-CimInstance Win32_SystemEnclosure | Select-Object -ExpandProperty ChassisTypes

    switch ($chassisType) {
        { $_ -in 3, 4, 5, 6, 7, 15, 16 } {
            return 'Desktop'
        }
        { $_ -in 8, 9, 10, 11, 12, 14, 18, 21, 31, 32 } {
            return 'Laptop'
        }
        { $_ -in 30 } {
            return 'Tablet'
        }
        { $_ -in 17, 23 } {
            return 'Server'
        }
        Default {
            Write-Warning ("Chassistype is {0}" -f $chassisType)
        }
    }
}
