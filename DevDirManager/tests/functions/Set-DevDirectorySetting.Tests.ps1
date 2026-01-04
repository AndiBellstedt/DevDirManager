Describe 'Set-DevDirectorySetting' -Tag 'Unit', 'Configuration' {

    Context "Parameter Contract" {
        BeforeAll {
            $command = Get-Command -Name 'Set-DevDirectorySetting'
            $parameters = $command.Parameters
        }

        Context "Parameter: RepositoryListPath" {
            BeforeAll { $p = $parameters['RepositoryListPath'] }
            It "Exists" { $p | Should -Not -BeNullOrEmpty }
            It "Is of type [string]" { $p.ParameterType.FullName | Should -Be 'System.String' }
            It "Is not Mandatory" { $p.Attributes.Where({$_ -is [System.Management.Automation.ParameterAttribute]}).Mandatory | Should -Not -Contain $true }
            It "Accepts ValueFromPipelineByPropertyName" { $p.Attributes.Where({$_ -is [System.Management.Automation.ParameterAttribute]}).ValueFromPipelineByPropertyName | Should -Contain $true }
        }

        Context "Parameter: LocalDevDirectory" {
            BeforeAll { $p = $parameters['LocalDevDirectory'] }
            It "Exists" { $p | Should -Not -BeNullOrEmpty }
            It "Is of type [string]" { $p.ParameterType.FullName | Should -Be 'System.String' }
            It "Is not Mandatory" { $p.Attributes.Where({$_ -is [System.Management.Automation.ParameterAttribute]}).Mandatory | Should -Not -Contain $true }
            It "Accepts ValueFromPipelineByPropertyName" { $p.Attributes.Where({$_ -is [System.Management.Automation.ParameterAttribute]}).ValueFromPipelineByPropertyName | Should -Contain $true }
        }

        Context "Parameter: AutoSyncEnabled" {
            BeforeAll { $p = $parameters['AutoSyncEnabled'] }
            It "Exists" { $p | Should -Not -BeNullOrEmpty }
            It "Is of type [bool]" { $p.ParameterType.FullName | Should -Be 'System.Boolean' }
            It "Is not Mandatory" { $p.Attributes.Where({$_ -is [System.Management.Automation.ParameterAttribute]}).Mandatory | Should -Not -Contain $true }
            It "Accepts ValueFromPipelineByPropertyName" { $p.Attributes.Where({$_ -is [System.Management.Automation.ParameterAttribute]}).ValueFromPipelineByPropertyName | Should -Contain $true }
        }

        Context "Parameter: SyncIntervalMinutes" {
            BeforeAll { $p = $parameters['SyncIntervalMinutes'] }
            It "Exists" { $p | Should -Not -BeNullOrEmpty }
            It "Is of type [int]" { $p.ParameterType.FullName | Should -Be 'System.Int32' }
            It "Is not Mandatory" { $p.Attributes.Where({$_ -is [System.Management.Automation.ParameterAttribute]}).Mandatory | Should -Not -Contain $true }
            It "Accepts ValueFromPipelineByPropertyName" { $p.Attributes.Where({$_ -is [System.Management.Automation.ParameterAttribute]}).ValueFromPipelineByPropertyName | Should -Contain $true }
            It "Has ValidateRange" { $p.Attributes.Where({$_ -is [System.Management.Automation.ValidateRangeAttribute]}) | Should -Not -BeNullOrEmpty }
        }

        Context "Parameter: Reset" {
            BeforeAll { $p = $parameters['Reset'] }
            It "Exists" { $p | Should -Not -BeNullOrEmpty }
            It "Is of type [switch]" { $p.ParameterType.FullName | Should -Be 'System.Management.Automation.SwitchParameter' }
            It "Is Mandatory in Reset set" { $p.Attributes.Where({$_ -is [System.Management.Automation.ParameterAttribute]}).Mandatory | Should -Contain $true }
        }

        Context "Parameter: PassThru" {
            BeforeAll { $p = $parameters['PassThru'] }
            It "Exists" { $p | Should -Not -BeNullOrEmpty }
            It "Is of type [switch]" { $p.ParameterType.FullName | Should -Be 'System.Management.Automation.SwitchParameter' }
            It "Is not Mandatory" { $p.Attributes.Where({$_ -is [System.Management.Automation.ParameterAttribute]}).Mandatory | Should -Not -Contain $true }
        }
    }

    Context 'Parameter Validation' {
        It 'Validates SyncIntervalMinutes range' {
            { Set-DevDirectorySetting -SyncIntervalMinutes 0 } | Should -Throw
        }
    }

    Context 'Functionality' {
        BeforeAll {
            # Mock all external dependencies to prevent any real operations.
            Mock 'Get-PSFConfigValue' -ModuleName 'DevDirManager' {
                param($FullName)
                switch ($FullName) {
                    'DevDirManager.SettingsPath' { return 'C:\Fake\Settings.json' }
                    'DevDirManager.ScheduledTaskName' { return 'FakeTaskName' }
                    default { return $null }
                }
            }

            # Mock file system operations to prevent real file access.
            Mock 'Test-Path' -ModuleName 'DevDirManager' {
                param($Path, $PathType)
                return $true
            }
            Mock 'Get-Content' -ModuleName 'DevDirManager' {
                return '{ "RepositoryListPath": "C:\\Fake\\Repo.json", "LocalDevDirectory": "C:\\Fake\\Dev", "SyncIntervalMinutes": 60, "AutoSyncEnabled": false }'
            }
            Mock 'New-Item' -ModuleName 'DevDirManager' { }
            Mock 'Write-ConfigFileWithRetry' -ModuleName 'DevDirManager' { }
            Mock 'Resolve-NormalizedPath' -ModuleName 'DevDirManager' { param($Path) return $Path }

            # Mock scheduled task operations.
            Mock 'Register-DevDirectoryScheduledSync' -ModuleName 'DevDirManager' { }
            Mock 'Unregister-DevDirectoryScheduledSync' -ModuleName 'DevDirManager' { }
        }

        It 'Updates settings and calls Write-ConfigFileWithRetry' {
            Set-DevDirectorySetting -SyncIntervalMinutes 120 -Confirm:$false
            Should -Invoke -CommandName 'Write-ConfigFileWithRetry' -Times 1 -ModuleName 'DevDirManager'
        }

        It 'Registers scheduled task when AutoSyncEnabled is set to true' {
            Set-DevDirectorySetting -AutoSyncEnabled $true -Confirm:$false
            Should -Invoke -CommandName 'Register-DevDirectoryScheduledSync' -Times 1 -ModuleName 'DevDirManager'
        }

        It 'Unregisters scheduled task when AutoSyncEnabled is set to false' {
            # Mock Get-Content to return config with AutoSyncEnabled = true so we can disable it.
            Mock 'Get-Content' -ModuleName 'DevDirManager' {
                return '{ "RepositoryListPath": "C:\\Fake\\Repo.json", "LocalDevDirectory": "C:\\Fake\\Dev", "SyncIntervalMinutes": 60, "AutoSyncEnabled": true }'
            }

            Set-DevDirectorySetting -AutoSyncEnabled $false -Confirm:$false
            Should -Invoke -CommandName 'Unregister-DevDirectoryScheduledSync' -Times 1 -ModuleName 'DevDirManager'
        }
    }

}
