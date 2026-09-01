Describe 'Select-WUBoundParameter' {
    It 'returns only requested entries that exist' {
        $boundParameters = [ordered]@{
            Name = 'Sample'
            WhatIf = $false
            Confirm = $true
            Other = 42
        }

        $result = Select-WUBoundParameter `
            -BoundParameters $boundParameters `
            -Name 'WhatIf', 'Confirm', 'Missing'

        $result | Should -BeOfType ([hashtable])
        $result.Count | Should -Be 2
        $result.ContainsKey('WhatIf') | Should -BeTrue
        $result.WhatIf | Should -BeFalse
        $result.Confirm | Should -BeTrue
        $result.ContainsKey('Missing') | Should -BeFalse
        $result.ContainsKey('Other') | Should -BeFalse
    }

    It 'preserves a null value for an existing entry' {
        $boundParameters = @{
            ErrorVariable = $null
        }

        $result = Select-WUBoundParameter `
            -BoundParameters $boundParameters `
            -Name 'ErrorVariable'

        $result.ContainsKey('ErrorVariable') | Should -BeTrue
        $result.ErrorVariable | Should -BeNullOrEmpty
    }

    It 'returns an empty hashtable when no requested entry exists' {
        $result = Select-WUBoundParameter `
            -BoundParameters @{ Name = 'Sample' } `
            -Name 'WhatIf', 'Confirm'

        $result | Should -BeOfType ([hashtable])
        $result.Count | Should -Be 0
    }
}
