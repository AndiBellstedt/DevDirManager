Describe "New-DevDirectorySyncRecord" -Tag "InternalFunction", "Data" {

    InModuleScope 'DevDirManager' {

        Context "Parameter Contract" {

            BeforeAll {
                $command = Get-Command -Name 'New-DevDirectorySyncRecord' -ErrorAction Stop
                $parameters = $command.Parameters
            }

            It "Should have the correct parameter types" {
                $parameters['RelativePath'].ParameterType.Name | Should -Be 'String'
                $parameters['RemoteUrl'].ParameterType.Name | Should -Be 'String'
                $parameters['RemoteName'].ParameterType.Name | Should -Be 'String'
                $parameters['RootDirectory'].ParameterType.Name | Should -Be 'String'
                $parameters['UserName'].ParameterType.Name | Should -Be 'String'
                $parameters['UserEmail'].ParameterType.Name | Should -Be 'String'
                $parameters['StatusDate'].ParameterType.Name | Should -Be 'DateTime'
            }

            It "Should have the correct mandatory parameters" {
                $parameters['RelativePath'].Attributes.Where({ $_ -is [System.Management.Automation.ParameterAttribute] }).Mandatory | Should -Contain $true
                $parameters['RootDirectory'].Attributes.Where({ $_ -is [System.Management.Automation.ParameterAttribute] }).Mandatory | Should -Contain $true
                $parameters['RemoteUrl'].Attributes.Where({ $_ -is [System.Management.Automation.ParameterAttribute] }).Mandatory | Should -Not -Contain $true
                $parameters['RemoteName'].Attributes.Where({ $_ -is [System.Management.Automation.ParameterAttribute] }).Mandatory | Should -Not -Contain $true
                $parameters['UserName'].Attributes.Where({ $_ -is [System.Management.Automation.ParameterAttribute] }).Mandatory | Should -Not -Contain $true
                $parameters['UserEmail'].Attributes.Where({ $_ -is [System.Management.Automation.ParameterAttribute] }).Mandatory | Should -Not -Contain $true
                $parameters['StatusDate'].Attributes.Where({ $_ -is [System.Management.Automation.ParameterAttribute] }).Mandatory | Should -Not -Contain $true
            }

            It "Should have the correct attributes" {
                $parameters['RelativePath'].Attributes.TypeId.Name | Should -Contain 'AllowEmptyStringAttribute'
                $parameters['RemoteUrl'].Attributes.TypeId.Name | Should -Contain 'AllowEmptyStringAttribute'
                $parameters['RemoteName'].Attributes.TypeId.Name | Should -Contain 'AllowEmptyStringAttribute'
                $parameters['RootDirectory'].Attributes.TypeId.Name | Should -Contain 'ValidateNotNullOrEmptyAttribute'
                $parameters['UserName'].Attributes.TypeId.Name | Should -Contain 'AllowNullAttribute'
                $parameters['UserEmail'].Attributes.TypeId.Name | Should -Contain 'AllowNullAttribute'
                $parameters['StatusDate'].Attributes.TypeId.Name | Should -Contain 'AllowNullAttribute'
            }

        }

        Context "Record construction" {

            It "Should build record with all properties" {
                $record = New-DevDirectorySyncRecord -RelativePath "ProjectA" -RemoteUrl "https://example/ProjectA.git" -RemoteName "origin" -RootDirectory "C:\Repos" -UserName "User" -UserEmail "user@example.com" -StatusDate (Get-Date).Date
                $record.PSObject.TypeNames[0] | Should -Be 'DevDirManager.Repository'
                $record.FullPath | Should -Be "C:\Repos\ProjectA"
                $record.RemoteUrl | Should -Be "https://example/ProjectA.git"
                $record.UserName | Should -Be "User"
                $record.StatusDate.Date | Should -Be (Get-Date).Date
            }

            It "Should normalize empty RelativePath to '.' and set FullPath to root" {
                $record = New-DevDirectorySyncRecord -RelativePath '' -RootDirectory "C:\Root" -RemoteName 'origin'
                $record.RelativePath | Should -Be '.'
                $record.FullPath | Should -Be "C:\Root"
            }

            It "Should allow null optional values" {
                $record = New-DevDirectorySyncRecord -RelativePath 'X' -RootDirectory 'C:\Dev'
                $record.RemoteUrl | Should -BeNullOrEmpty
                $record.UserEmail | Should -BeNullOrEmpty
            }

        }

    }

}
