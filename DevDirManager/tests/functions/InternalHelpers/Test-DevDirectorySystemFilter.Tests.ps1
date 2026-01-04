Describe 'Test-DevDirectorySystemFilter' -Tag 'Unit', 'Internal', 'Filter' {

    InModuleScope 'DevDirManager' {

        Context "Parameter Contract" {

            BeforeAll {
                $command = Get-Command -Name 'Test-DevDirectorySystemFilter' -ErrorAction Stop
                $parameters = $command.Parameters
            }

            It "Should have the correct parameter types" {
                $parameters['SystemFilter'].ParameterType.Name | Should -Be 'String'
                $parameters['ComputerName'].ParameterType.Name | Should -Be 'String'
            }

            It "Should have the correct mandatory parameters" {
                $parameters['SystemFilter'].Attributes.Where({$_ -is [System.Management.Automation.ParameterAttribute]}).Mandatory | Should -Contain $true
                $parameters['ComputerName'].Attributes.Where({$_ -is [System.Management.Automation.ParameterAttribute]}).Mandatory | Should -Not -Contain $true
            }

            It "Should have the correct attributes" {
                $parameters['SystemFilter'].Attributes.TypeId.Name | Should -Contain 'AllowNullAttribute'
                $parameters['SystemFilter'].Attributes.TypeId.Name | Should -Contain 'AllowEmptyStringAttribute'
            }

        }

        Context 'Inclusion Filters' {

            It 'Returns true when computer name matches exact filter' {
                Test-DevDirectorySystemFilter -SystemFilter 'PC01' -ComputerName 'PC01' | Should -BeTrue
            }

            It 'Returns true when computer name matches wildcard filter' {
                Test-DevDirectorySystemFilter -SystemFilter 'PC*' -ComputerName 'PC01' | Should -BeTrue
            }

            It 'Returns false when computer name does not match filter' {
                Test-DevDirectorySystemFilter -SystemFilter 'Server*' -ComputerName 'PC01' | Should -BeFalse
            }

            It 'Returns true when filter is *' {
                Test-DevDirectorySystemFilter -SystemFilter '*' -ComputerName 'AnyPC' | Should -BeTrue
            }

        }

        Context 'Exclusion Filters' {

            It 'Returns false when computer name matches exclusion' {
                Test-DevDirectorySystemFilter -SystemFilter '!PC01' -ComputerName 'PC01' | Should -BeFalse
            }

            It 'Returns true when computer name does not match exclusion' {
                Test-DevDirectorySystemFilter -SystemFilter '!Server*' -ComputerName 'PC01' | Should -BeTrue
            }

        }

        Context 'Complex Filters' {

            It 'Returns true when matching inclusion and not matching exclusion' {
                Test-DevDirectorySystemFilter -SystemFilter 'PC*,!PC99' -ComputerName 'PC01' | Should -BeTrue
            }

            It 'Returns false when matching inclusion but also matching exclusion' {
                Test-DevDirectorySystemFilter -SystemFilter 'PC*,!PC01' -ComputerName 'PC01' | Should -BeFalse
            }

        }

    }

}
