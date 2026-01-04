Describe "Resolve-RepositoryListFormat" -Tag "InternalFunction", "Parsing" {

    InModuleScope 'DevDirManager' {

        Context "Parameter Contract" {

            BeforeAll {
                $command = Get-Command -Name 'Resolve-RepositoryListFormat' -ErrorAction Stop
                $parameters = $command.Parameters
            }

            It "Should have the correct parameter types" {
                $parameters['Path'].ParameterType.Name | Should -Be 'String'
                $parameters['Format'].ParameterType.Name | Should -Be 'String'
                $parameters['DefaultFormat'].ParameterType.Name | Should -Be 'String'
                $parameters['ErrorContext'].ParameterType.Name | Should -Be 'String'
            }

            It "Should have the correct mandatory parameters" {
                $parameters['Path'].Attributes.Where({ $_ -is [System.Management.Automation.ParameterAttribute] }).Mandatory | Should -Contain $true
                $parameters['Format'].Attributes.Where({ $_ -is [System.Management.Automation.ParameterAttribute] }).Mandatory | Should -Not -Contain $true
                $parameters['DefaultFormat'].Attributes.Where({ $_ -is [System.Management.Automation.ParameterAttribute] }).Mandatory | Should -Not -Contain $true
                $parameters['ErrorContext'].Attributes.Where({ $_ -is [System.Management.Automation.ParameterAttribute] }).Mandatory | Should -Not -Contain $true
            }

            It "Should have the correct attributes" {
                $parameters['Format'].Attributes.TypeId.Name | Should -Contain 'ValidateSetAttribute'
                $parameters['DefaultFormat'].Attributes.TypeId.Name | Should -Contain 'ValidateSetAttribute'

            }

        }

        Context "Format detection from file extension" {

            It "Should detect CSV from .csv extension" {
                $format = Resolve-RepositoryListFormat -Path "C:\repos\list.csv"
                $format | Should -Be "CSV"
            }

            It "Should detect JSON from .json extension" {
                $format = Resolve-RepositoryListFormat -Path "C:\repos\list.json"
                $format | Should -Be "JSON"
            }

            It "Should detect XML from .xml extension" {
                $format = Resolve-RepositoryListFormat -Path "C:\repos\list.xml"
                $format | Should -Be "XML"
            }

            It "Should be case-insensitive" {
                Resolve-RepositoryListFormat -Path "repos.CSV" | Should -Be "CSV"
                Resolve-RepositoryListFormat -Path "repos.Json" | Should -Be "JSON"
                Resolve-RepositoryListFormat -Path "repos.XML" | Should -Be "XML"
            }

        }

        Context "Explicit format override" {

            It "Should use explicit format when provided" {
                $format = Resolve-RepositoryListFormat -Path "repos.txt" -Format "JSON"
                $format | Should -Be "JSON"
            }

        }

        Context "Default format fallback" {

            It "Should use default format for unknown extension" {
                $format = Resolve-RepositoryListFormat -Path "repos.txt" -DefaultFormat "CSV"
                $format | Should -Be "CSV"
            }

        }

        Context "Error handling" {

            It "Should throw when format cannot be inferred" {
                { Resolve-RepositoryListFormat -Path "repos.unknown" -ErrorAction Stop } | Should -Throw
            }

        }

    }

}
