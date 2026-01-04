Describe 'Register-DevDirectoryScheduledSync' -Tag 'Unit', 'Automation' {

    Context "Parameter Contract" {
        BeforeAll {
            $command = Get-Command -Name 'Register-DevDirectoryScheduledSync'
            $parameters = $command.Parameters
        }

        Context "Parameter: RunAtLogon" {
            BeforeAll { $p = $parameters['RunAtLogon'] }
            It "Exists" { $p | Should -Not -BeNullOrEmpty }
            It "Is of type [switch]" { $p.ParameterType.FullName | Should -Be 'System.Management.Automation.SwitchParameter' }
            It "Is not Mandatory" { $p.Attributes.Where({ $_ -is [System.Management.Automation.ParameterAttribute] }).Mandatory | Should -Not -Contain $true }
        }

        Context "Parameter: Force" {
            BeforeAll { $p = $parameters['Force'] }
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
                if ($Name -eq 'SyncIntervalMinutes') { return 120 }
                return [PSCustomObject]@{
                    RepositoryListPath  = 'C:\Fake\Repo.json'
                    LocalDevDirectory   = 'C:\Fake\Dev'
                    SyncIntervalMinutes = 120
                    AutoSyncEnabled     = $false
                }
            }

            # Mock scheduled task cmdlets to prevent real task creation.
            Mock 'Get-ScheduledTask' -ModuleName 'DevDirManager' { return $null }
            Mock 'Register-ScheduledTask' -ModuleName 'DevDirManager' { return [PSCustomObject]@{ TaskName = 'FakeTaskName'; State = 'Ready' } }
            Mock 'Unregister-ScheduledTask' -ModuleName 'DevDirManager' { }

            # Mock file operations.
            Mock 'Get-Content' -ModuleName 'DevDirManager' {
                return '{ "RepositoryListPath": "C:\\Fake\\Repo.json", "LocalDevDirectory": "C:\\Fake\\Dev", "SyncIntervalMinutes": 120, "AutoSyncEnabled": false }'
            }
            Mock 'Write-ConfigFileWithRetry' -ModuleName 'DevDirManager' { }
        }

        It 'Registers a scheduled task' {
            Register-DevDirectoryScheduledSync -Force -Confirm:$false
            Should -Invoke -CommandName 'Register-ScheduledTask' -Times 1 -ModuleName 'DevDirManager'
        }

        It 'Updates configuration to enable AutoSync' {
            Register-DevDirectoryScheduledSync -Force -Confirm:$false
            Should -Invoke -CommandName 'Write-ConfigFileWithRetry' -Times 1 -ModuleName 'DevDirManager'
        }

        It 'Throws if configuration is missing' {
            Mock 'Get-DevDirectorySetting' -ModuleName 'DevDirManager' {
                param($Name)
                if ($Name -eq 'RepositoryListPath') { return $null }
                if ($Name -eq 'LocalDevDirectory') { return $null }
                return [PSCustomObject]@{ RepositoryListPath = $null; LocalDevDirectory = $null }
            }
            { Register-DevDirectoryScheduledSync -Confirm:$false } | Should -Throw
        }

    }

}
