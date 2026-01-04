Describe "Get-DevDirectoryRemoteUrl" -Tag "InternalFunction", "Git" {

    InModuleScope 'DevDirManager' {

        Context "Parameter Contract" {

            BeforeAll {
                $command = Get-Command -Name 'Get-DevDirectoryRemoteUrl' -ErrorAction Stop
                $parameters = $command.Parameters
            }

            It "Should have the correct parameter types" {
                $parameters['RepositoryPath'].ParameterType.Name | Should -Be 'String'
                $parameters['RemoteName'].ParameterType.Name | Should -Be 'String'
            }

            It "Should have the correct mandatory parameters" {
                $parameters['RepositoryPath'].Attributes.Where({ $_ -is [System.Management.Automation.ParameterAttribute] }).Mandatory | Should -Contain $true
                $parameters['RemoteName'].Attributes.Where({ $_ -is [System.Management.Automation.ParameterAttribute] }).Mandatory | Should -Contain $true
            }

            It "Should have the correct attributes" {
                $parameters['RepositoryPath'].Attributes.TypeId.Name | Should -Contain 'ValidateNotNullOrEmptyAttribute'
                $parameters['RemoteName'].Attributes.TypeId.Name | Should -Contain 'ValidateNotNullOrEmptyAttribute'
            }

        }

        BeforeAll {
            $script:repoRoot = Join-Path $TestDrive "RepoRemote"
            New-Item -ItemType Directory -Path $script:repoRoot -Force | Out-Null
            $gitDir = Join-Path $script:repoRoot ".git"
            New-Item -ItemType Directory -Path $gitDir -Force | Out-Null
        }

        AfterAll {
            if (Test-Path $script:repoRoot) {
                Remove-Item -Path $script:repoRoot -Recurse -Force -ErrorAction SilentlyContinue
            }
        }

        Context "Remote URL parsing" {

            It "Should return null when config missing" {
                Get-DevDirectoryRemoteUrl -RepositoryPath $script:repoRoot -RemoteName origin | Should -Be $null
            }

            It "Should parse remote URL for origin" {
                $configPath = Join-Path $script:repoRoot ".git\config"
                @"
[remote "origin"]
    url = https://example/repo.git
"@ | Set-Content -LiteralPath $configPath -Encoding UTF8
                Get-DevDirectoryRemoteUrl -RepositoryPath $script:repoRoot -RemoteName origin | Should -Be "https://example/repo.git"
            }

            It "Should return null when remote not present" {
                $configPath = Join-Path $script:repoRoot ".git\config"
                @"
[remote "upstream"]
    url = https://example/upstream.git
"@ | Set-Content -LiteralPath $configPath -Encoding UTF8
                Get-DevDirectoryRemoteUrl -RepositoryPath $script:repoRoot -RemoteName origin | Should -Be $null
            }

            It "Should parse remote with different name" {
                $configPath = Join-Path $script:repoRoot ".git\config"
                @"
[remote "secondary"]
    url = ssh://git@example/repo2.git
"@ | Set-Content -LiteralPath $configPath -Encoding UTF8
                Get-DevDirectoryRemoteUrl -RepositoryPath $script:repoRoot -RemoteName secondary | Should -Be "ssh://git@example/repo2.git"
            }

        }

    }

}
