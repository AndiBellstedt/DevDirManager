Describe 'Unregister-DevDirectoryScheduledSync' -Tag 'Unit', 'Automation' {

    Context "Parameter Contract" {
        BeforeAll {
            $command = Get-Command -Name 'Unregister-DevDirectoryScheduledSync'
            $parameters = $command.Parameters
        }

        It "Has no parameters" {
            # Common parameters are always present (Verbose, Debug, etc.)
            # We check if there are any specific parameters
            $commonParams = 'Verbose', 'Debug', 'ErrorAction', 'WarningAction', 'InformationAction', 'ErrorVariable', 'WarningVariable', 'InformationVariable', 'OutVariable', 'OutBuffer', 'PipelineVariable', 'WhatIf', 'Confirm', 'ProgressAction'
            $specificParams = $parameters.Keys | Where-Object { $_ -notin $commonParams }
            $specificParams | Should -BeNullOrEmpty
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

            # Mock scheduled task cmdlets to prevent real task operations.
            Mock 'Get-ScheduledTask' -ModuleName 'DevDirManager' { return [PSCustomObject]@{ TaskName = 'FakeTaskName'; State = 'Ready' } }
            Mock 'Unregister-ScheduledTask' -ModuleName 'DevDirManager' { }

            # Mock file operations to prevent real config file access.
            Mock 'Get-Content' -ModuleName 'DevDirManager' { return '{ "AutoSyncEnabled": true }' }
            Mock 'Write-ConfigFileWithRetry' -ModuleName 'DevDirManager' { }
        }

        It 'Unregisters the scheduled task' {
            Unregister-DevDirectoryScheduledSync -Confirm:$false
            Should -Invoke -CommandName 'Unregister-ScheduledTask' -Times 1 -ModuleName 'DevDirManager'
        }

        It 'Updates configuration to disable AutoSync' {
            Unregister-DevDirectoryScheduledSync -Confirm:$false
            Should -Invoke -CommandName 'Write-ConfigFileWithRetry' -Times 1 -ModuleName 'DevDirManager'
        }

    }

}
