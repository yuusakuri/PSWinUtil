function Convert-WUStringToBool {
    <#
        .SYNOPSIS
        Converts a string representation of a boolean value into a Boolean type.

        .DESCRIPTION
        This function takes a string input and converts it into a Boolean value.
        Recognized true values are: "yes", "y", "true" (case-insensitive).
        Recognized false values are: "no", "n", "false" (case-insensitive).
        If the input string does not match any predefined values, the function returns nothing.

        .PARAMETER String
        The string value to be converted into a Boolean. Accepts input from the pipeline.

        .OUTPUTS
        System.Boolean
        Returns $true or $false if the input matches a predefined value.
        If the input does not match any known values, it returns no output.

        .EXAMPLE
        Convert-StringToBool -String "yes"
        Returns: True

        .EXAMPLE
        "no" | Convert-StringToBool
        Returns: False

        .EXAMPLE
        Convert-StringToBool -String "unknown"
        Returns: (no output)
    #>
    [CmdletBinding()]
    param (
        # Specifies the string to be converted. Accepts pipeline input.
        [Parameter(Position = 0,
            ValueFromPipeline,
            ValueFromPipelineByPropertyName)]
        [string]
        $String
    )

    begin {
        Set-StrictMode -Version 'Latest'
    }

    process {
        $trueStrings = @(
            'yes'
            'y'
            'true'
        )
        $falseStrings = @(
            'no'
            'n'
            'false'
        )

        if ($String -in $trueStrings) {
            return $true
        }
        if ($String -in $falseStrings) {
            return $false
        }
    }
}
