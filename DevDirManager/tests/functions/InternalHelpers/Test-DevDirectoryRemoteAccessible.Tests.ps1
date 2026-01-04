Describe "Test-DevDirectoryRemoteAccessible" -Tag "InternalFunction", "Git", "Remote" {

    InModuleScope 'DevDirManager' {

        Context "Parameter Contract" {

            BeforeAll {
                $command = Get-Command -Name 'Test-DevDirectoryRemoteAccessible' -ErrorAction Stop
                $parameters = $command.Parameters
            }

            It "Should have the correct parameter types" {
                $parameters['RemoteUrl'].ParameterType.Name | Should -Be 'String'
                $parameters['GitExecutable'].ParameterType.Name | Should -Be 'String'
                $parameters['TimeoutSeconds'].ParameterType.Name | Should -Be 'Int32'
            }

            It "Should have the correct mandatory parameters" {
                $parameters['RemoteUrl'].Attributes.Where({ $_ -is [System.Management.Automation.ParameterAttribute] }).Mandatory | Should -Contain $true
                $parameters['GitExecutable'].Attributes.Where({ $_ -is [System.Management.Automation.ParameterAttribute] }).Mandatory | Should -Not -Contain $true
                $parameters['TimeoutSeconds'].Attributes.Where({ $_ -is [System.Management.Automation.ParameterAttribute] }).Mandatory | Should -Not -Contain $true
            }

            It "Should have the correct attributes" {
                $parameters['RemoteUrl'].Attributes.TypeId.Name | Should -Contain 'ValidateNotNullOrEmptyAttribute'
            }

        }

        Context "Input validation" {

            It "Should return false for whitespace URL" {
                $result = Test-DevDirectoryRemoteAccessible -RemoteUrl '   '
                $result | Should -BeFalse
            }

        }

        Context "Timeout unreachable remote" {

            It "Should return false for unreachable remote quickly" {
                $result = Test-DevDirectoryRemoteAccessible -RemoteUrl 'https://nonexistent.invalid/repo.git' -TimeoutSeconds 1
                $result | Should -BeFalse

            }

        }

    }

}
