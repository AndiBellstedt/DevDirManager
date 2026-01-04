Describe 'Invoke-DevDirectorySyncSchedule' -Tag 'Unit', 'Automation' {

    Context "Parameter Contract" {
        BeforeAll {
            $command = Get-Command -Name 'Invoke-DevDirectorySyncSchedule'
            $parameters = $command.Parameters
        }

        Context "Invoke-DevDirectorySyncSchedule - Parameter: Force" {
            BeforeAll { $p = $parameters['Force'] }
            It "Exists" { $p | Should -Not -BeNullOrEmpty }
            It "Is of type [switch]" { $p.ParameterType.FullName | Should -Be 'System.Management.Automation.SwitchParameter' }
            It "Is not Mandatory" { $p.Attributes.Where({ $_ -is [System.Management.Automation.ParameterAttribute] }).Mandatory | Should -Not -Contain $true }
        }

        Context "Invoke-DevDirectorySyncSchedule - Parameter: SkipExisting" {
            BeforeAll { $p = $parameters['SkipExisting'] }
            It "Exists" { $p | Should -Not -BeNullOrEmpty }
            It "Is of type [switch]" { $p.ParameterType.FullName | Should -Be 'System.Management.Automation.SwitchParameter' }
            It "Is not Mandatory" { $p.Attributes.Where({ $_ -is [System.Management.Automation.ParameterAttribute] }).Mandatory | Should -Not -Contain $true }
        }

        Context "Invoke-DevDirectorySyncSchedule - Parameter: ShowGitOutput" {
            BeforeAll { $p = $parameters['ShowGitOutput'] }
            It "Exists" { $p | Should -Not -BeNullOrEmpty }
            It "Is of type [switch]" { $p.ParameterType.FullName | Should -Be 'System.Management.Automation.SwitchParameter' }
            It "Is not Mandatory" { $p.Attributes.Where({ $_ -is [System.Management.Automation.ParameterAttribute] }).Mandatory | Should -Not -Contain $true }
        }

        Context "Invoke-DevDirectorySyncSchedule - Parameter: PassThru" {
            BeforeAll { $p = $parameters['PassThru'] }
            It "Exists" { $p | Should -Not -BeNullOrEmpty }
            It "Is of type [switch]" { $p.ParameterType.FullName | Should -Be 'System.Management.Automation.SwitchParameter' }
            It "Is not Mandatory" { $p.Attributes.Where({ $_ -is [System.Management.Automation.ParameterAttribute] }).Mandatory | Should -Not -Contain $true }
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

            Mock 'Get-DevDirectorySetting' -ModuleName 'DevDirManager' {
                param($Name)

                if ($Name -eq 'RepositoryListPath') { return 'C:\Fake\Repo.json' }
                if ($Name -eq 'LocalDevDirectory') { return 'C:\Fake\Dev' }
                if ($Name -eq 'SyncIntervalMinutes') { return 60 }

                return [PSCustomObject]@{
                    RepositoryListPath  = 'C:\Fake\Repo.json'
                    LocalDevDirectory   = 'C:\Fake\Dev'
                    SyncIntervalMinutes = 60
                    AutoSyncEnabled     = $true
                    LastSyncTime        = (Get-Date).AddHours(-2)
                }
            }

            # Mock file system operations to prevent real file access.
            Mock 'Test-Path' -ModuleName 'DevDirManager' { return $true }
            Mock 'Get-Content' -ModuleName 'DevDirManager' { return '{}' }
            Mock 'Set-Content' -ModuleName 'DevDirManager' { }
            Mock 'Remove-Item' -ModuleName 'DevDirManager' { }

            # Mock repository operations to prevent real sync.
            Mock 'Import-DevDirectoryList' -ModuleName 'DevDirManager' { return @([PSCustomObject]@{ Name = 'FakeRepo'; RelativePath = 'FakeRepo'; RemoteUrl = 'https://fake.url'; SystemFilter = '*' }) }
            Mock 'Export-DevDirectoryList' -ModuleName 'DevDirManager' { }
            Mock 'Sync-DevDirectoryList' -ModuleName 'DevDirManager' { }
            Mock 'Test-DevDirectorySystemFilter' -ModuleName 'DevDirManager' { return $true }
            Mock 'Write-ConfigFileWithRetry' -ModuleName 'DevDirManager' { }
        }

        It 'Invokes Sync-DevDirectoryList when interval has passed' {
            Invoke-DevDirectorySyncSchedule -Confirm:$false
            Should -Invoke -CommandName 'Sync-DevDirectoryList' -Times 1 -ModuleName 'DevDirManager'
        }

        It 'Updates LastSyncTime after sync' {
            Invoke-DevDirectorySyncSchedule -Confirm:$false
            Should -Invoke -CommandName 'Write-ConfigFileWithRetry' -Times 1 -ModuleName 'DevDirManager'
        }

    }

}
