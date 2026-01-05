Describe 'Get-DevDirectorySetting' -Tag 'Unit', 'Configuration' {

    Context "Parameter Contract" {
        BeforeAll {
            $command = Get-Command -Name 'Get-DevDirectorySetting'
            $parameters = $command.Parameters
        }

        Context "Get-DevDirectorySetting - Parameter: Name" {
            BeforeAll { $p = $parameters['Name'] }
            It "Exists" { $p | Should -Not -BeNullOrEmpty }
            It "Is of type [string]" { $p.ParameterType.FullName | Should -Be 'System.String' }
            It "Is not Mandatory" { $p.Attributes.Where({ $_ -is [System.Management.Automation.ParameterAttribute] }).Mandatory | Should -Not -Contain $true }
            It "Accepts ValueFromPipeline" { $p.Attributes.Where({ $_ -is [System.Management.Automation.ParameterAttribute] }).ValueFromPipeline | Should -Contain $true }
            It "Accepts ValueFromPipelineByPropertyName" { $p.Attributes.Where({ $_ -is [System.Management.Automation.ParameterAttribute] }).ValueFromPipelineByPropertyName | Should -Contain $true }
            It "Has ValidateSet" {
                $set = $p.Attributes.Where({ $_ -is [System.Management.Automation.ValidateSetAttribute] })
                $set | Should -Not -BeNullOrEmpty
                $set.ValidValues | Should -Contain "RepositoryListPath"
                $set.ValidValues | Should -Contain "LocalDevDirectory"
                $set.ValidValues | Should -Contain "AutoSyncEnabled"
                $set.ValidValues | Should -Contain "SyncIntervalMinutes"
                $set.ValidValues | Should -Contain "LastSyncTime"
                $set.ValidValues | Should -Contain "LastSyncResult"
                $set.ValidValues | Should -Contain "All"
                $set.ValidValues | Should -Contain "*"
            }
        }
    }

    Context 'Parameter Validation' {
        It 'Validates Name parameter set' {
            { Get-DevDirectorySetting -Name 'InvalidName' } | Should -Throw
        }
    }

    Context 'Functionality' {
        BeforeAll {
            # Create a temporary config file for isolated testing.
            $script:tempConfig = [System.IO.Path]::GetTempFileName()
            $configContent = @{
                RepositoryListPath  = 'C:\Fake\Repo.json'
                LocalDevDirectory   = 'C:\Fake\Dev'
                SyncIntervalMinutes = 60
                AutoSyncEnabled     = $true
            } | ConvertTo-Json
            Set-Content -Path $script:tempConfig -Value $configContent -Encoding UTF8

            # Mock Get-PSFConfigValue to return our temp file path.
            Mock 'Get-PSFConfigValue' -ModuleName 'DevDirManager' {
                param($FullName)
                if ($FullName -eq 'DevDirManager.SettingsPath') {
                    return $script:tempConfig
                }
                return $null
            }
        }

        AfterAll {
            # Clean up temp file.
            if (Test-Path $script:tempConfig) {
                Remove-Item $script:tempConfig -Force -ErrorAction SilentlyContinue
            }
        }

        It 'Returns all settings when no parameter is specified' {
            $settings = Get-DevDirectorySetting
            $settings | Should -Not -BeNull
            $settings.SyncIntervalMinutes | Should -Be 60
        }

        It 'Returns specific setting when Name is specified' {
            Get-DevDirectorySetting -Name 'SyncIntervalMinutes' | Should -Be 60
            Get-DevDirectorySetting -Name 'AutoSyncEnabled' | Should -BeTrue
        }
    }

}
