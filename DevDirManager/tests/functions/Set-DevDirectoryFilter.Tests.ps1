Describe 'Set-DevDirectoryFilter' -Tag 'Unit', 'SystemFilter' {

    Context "Parameter Contract" {

        BeforeAll {
            $command = Get-Command -Name 'Set-DevDirectoryFilter'
            $parameters = $command.Parameters
        }

        Context "Set-DevDirectoryFilter - Parameter: InputObject" {
            BeforeAll { $p = $parameters['InputObject'] }
            It "Exists" { $p | Should -Not -BeNullOrEmpty }
            It "Is of type [psobject[]]" { $p.ParameterType.FullName | Should -Be 'System.Management.Automation.PSObject[]' }
            It "Is Mandatory" { $p.Attributes.Where({ $_ -is [System.Management.Automation.ParameterAttribute] }).Mandatory | Should -Contain $true }
            It "Accepts ValueFromPipeline" { $p.Attributes.Where({ $_ -is [System.Management.Automation.ParameterAttribute] }).ValueFromPipeline | Should -Contain $true }
            It "Accepts ValueFromPipelineByPropertyName" { $p.Attributes.Where({ $_ -is [System.Management.Automation.ParameterAttribute] }).ValueFromPipelineByPropertyName | Should -Contain $true }
        }

        Context "Set-DevDirectoryFilter - Parameter: SystemFilter" {
            BeforeAll { $p = $parameters['SystemFilter'] }
            It "Exists" { $p | Should -Not -BeNullOrEmpty }
            It "Is of type [string]" { $p.ParameterType.FullName | Should -Be 'System.String' }
            It "Is Mandatory in Set parameter set" {
                $setParamAttr = $p.Attributes.Where({ $_ -is [System.Management.Automation.ParameterAttribute] -and $_.ParameterSetName -eq 'Set' })
                $setParamAttr.Mandatory | Should -Contain $true
            }
            It "Allows null values" { $p.Attributes.Where({ $_ -is [System.Management.Automation.AllowNullAttribute] }) | Should -Not -BeNullOrEmpty }
            It "Allows empty string" { $p.Attributes.Where({ $_ -is [System.Management.Automation.AllowEmptyStringAttribute] }) | Should -Not -BeNullOrEmpty }
        }

        Context "Set-DevDirectoryFilter - Parameter: Clear" {
            BeforeAll { $p = $parameters['Clear'] }
            It "Exists" { $p | Should -Not -BeNullOrEmpty }
            It "Is of type [switch]" { $p.ParameterType.FullName | Should -Be 'System.Management.Automation.SwitchParameter' }
            It "Is Mandatory in Clear parameter set" {
                $clearParamAttr = $p.Attributes.Where({ $_ -is [System.Management.Automation.ParameterAttribute] -and $_.ParameterSetName -eq 'Clear' })
                $clearParamAttr.Mandatory | Should -Contain $true
            }
        }

        Context "Set-DevDirectoryFilter - Parameter: PassThru" {
            BeforeAll { $p = $parameters['PassThru'] }
            It "Exists" { $p | Should -Not -BeNullOrEmpty }
            It "Is of type [switch]" { $p.ParameterType.FullName | Should -Be 'System.Management.Automation.SwitchParameter' }
            It "Is not Mandatory" { $p.Attributes.Where({ $_ -is [System.Management.Automation.ParameterAttribute] }).Mandatory | Should -Not -Contain $true }
        }

        Context "Set-DevDirectoryFilter - Parameter Sets" {
            It "Has 'Set' parameter set" { $command.ParameterSets.Name | Should -Contain 'Set' }
            It "Has 'Clear' parameter set" { $command.ParameterSets.Name | Should -Contain 'Clear' }
            It "Default parameter set is 'Set'" { $command.DefaultParameterSet | Should -Be 'Set' }
        }

    }

    Context 'Functionality' {

        BeforeAll {
            # Create mock repository objects for testing.
            $mockRepoWithFilter = [pscustomobject]@{
                PSTypeName   = 'DevDirManager.Repository'
                RelativePath = 'TestProject'
                RemoteUrl    = 'https://github.com/test/repo.git'
                SystemFilter = 'DEV-*'
            }

            $mockRepoWithoutFilter = [pscustomobject]@{
                PSTypeName   = 'DevDirManager.Repository'
                RelativePath = 'AnotherProject'
                RemoteUrl    = 'https://github.com/test/another.git'
            }
        }

        Context 'Setting SystemFilter' {

            It 'Sets SystemFilter on object that already has the property' {
                $repo = $mockRepoWithFilter.PSObject.Copy()
                $result = $repo | Set-DevDirectoryFilter -SystemFilter 'WORK-*' -PassThru

                $result.SystemFilter | Should -Be 'WORK-*'
            }

            It 'Adds SystemFilter property to object that does not have it' {
                $repo = $mockRepoWithoutFilter.PSObject.Copy()
                $result = $repo | Set-DevDirectoryFilter -SystemFilter 'HOME-PC' -PassThru

                $result.SystemFilter | Should -Be 'HOME-PC'
            }

            It 'Sets empty string as null (cleared)' {
                $repo = $mockRepoWithFilter.PSObject.Copy()
                $result = $repo | Set-DevDirectoryFilter -SystemFilter '' -PassThru

                $result.SystemFilter | Should -BeNullOrEmpty
            }

            It 'Sets complex filter pattern' {
                $repo = $mockRepoWithFilter.PSObject.Copy()
                $result = $repo | Set-DevDirectoryFilter -SystemFilter 'DEV-*,LAPTOP-*,!DEV-BUILD' -PassThru

                $result.SystemFilter | Should -Be 'DEV-*,LAPTOP-*,!DEV-BUILD'
            }

        }

        Context 'Clearing SystemFilter' {

            It 'Clears existing SystemFilter using -Clear switch' {
                $repo = $mockRepoWithFilter.PSObject.Copy()
                $result = $repo | Set-DevDirectoryFilter -Clear -PassThru

                $result.SystemFilter | Should -BeNullOrEmpty
            }

            It 'Clears SystemFilter on object without the property (adds null property)' {
                $repo = $mockRepoWithoutFilter.PSObject.Copy()
                $result = $repo | Set-DevDirectoryFilter -Clear -PassThru

                $result.PSObject.Properties['SystemFilter'] | Should -Not -BeNullOrEmpty
                $result.SystemFilter | Should -BeNullOrEmpty
            }

        }

        Context 'PassThru behavior' {

            It 'Returns nothing when -PassThru is not specified' {
                $repo = $mockRepoWithFilter.PSObject.Copy()
                $result = $repo | Set-DevDirectoryFilter -SystemFilter 'TEST-*'

                $result | Should -BeNullOrEmpty
            }

            It 'Returns modified object when -PassThru is specified' {
                $repo = $mockRepoWithFilter.PSObject.Copy()
                $result = $repo | Set-DevDirectoryFilter -SystemFilter 'TEST-*' -PassThru

                $result | Should -Not -BeNullOrEmpty
                $result.RelativePath | Should -Be 'TestProject'
            }

        }

        Context 'Pipeline processing' {

            It 'Processes multiple objects from pipeline' {
                $repos = @(
                    [pscustomobject]@{ RelativePath = 'Repo1'; RemoteUrl = 'url1' }
                    [pscustomobject]@{ RelativePath = 'Repo2'; RemoteUrl = 'url2' }
                    [pscustomobject]@{ RelativePath = 'Repo3'; RemoteUrl = 'url3' }
                )

                $results = $repos | Set-DevDirectoryFilter -SystemFilter 'BATCH-*' -PassThru

                $results.Count | Should -Be 3
                $results | ForEach-Object { $_.SystemFilter | Should -Be 'BATCH-*' }
            }

            It 'Preserves other properties when setting filter' {
                $repo = [pscustomobject]@{
                    RelativePath = 'MyRepo'
                    RemoteUrl    = 'https://example.com/repo.git'
                    UserName     = 'TestUser'
                    UserEmail    = 'test@example.com'
                    StatusDate   = (Get-Date)
                }

                $result = $repo | Set-DevDirectoryFilter -SystemFilter 'PRESERVE-*' -PassThru

                $result.RelativePath | Should -Be 'MyRepo'
                $result.RemoteUrl | Should -Be 'https://example.com/repo.git'
                $result.UserName | Should -Be 'TestUser'
                $result.UserEmail | Should -Be 'test@example.com'
                $result.SystemFilter | Should -Be 'PRESERVE-*'
            }

        }

        Context 'WhatIf support' {

            It 'Supports -WhatIf parameter' {
                $repo = $mockRepoWithFilter.PSObject.Copy()
                $originalFilter = $repo.SystemFilter

                $repo | Set-DevDirectoryFilter -SystemFilter 'CHANGED-*' -WhatIf

                # The original object should not be modified when using -WhatIf.
                $repo.SystemFilter | Should -Be $originalFilter
            }

        }

    }

}
