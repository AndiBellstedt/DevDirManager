Describe 'Get-DevDirectoryStatusDate Internal Function' -Tag 'Unit', 'Internal' {

    InModuleScope 'DevDirManager' {

        Context "Parameter Contract" {

            BeforeAll {
                $command = Get-Command -Name 'Get-DevDirectoryStatusDate' -ErrorAction Stop
                $parameters = $command.Parameters
            }

            It "Should have the correct parameter types" {
                $parameters['RepositoryPath'].ParameterType.Name | Should -Be 'String'
            }

            It "Should have the correct mandatory parameters" {
                $parameters['RepositoryPath'].Attributes.Where({ $_ -is [System.Management.Automation.ParameterAttribute] }).Mandatory | Should -Contain $true
            }

            It "Should have the correct attributes" {
                $parameters['RepositoryPath'].Attributes.TypeId.Name | Should -Contain 'ValidateNotNullOrEmptyAttribute'
            }

        }

        Context 'Status Date Extraction' {

            BeforeAll {
                $script:TestRoot = Join-Path -Path $TestDrive -ChildPath 'StatusDateTests'
                New-Item -Path $script:TestRoot -ItemType Directory -Force | Out-Null

                function New-MockGitRepository {
                    param(
                        [string]$Path,
                        [string]$UserName,
                        [string]$UserEmail,
                        [string]$RemoteUrl = 'https://github.com/test/repo.git'
                    )

                    $gitDir = Join-Path -Path $Path -ChildPath '.git'
                    New-Item -Path $gitDir -ItemType Directory -Force | Out-Null

                    $configPath = Join-Path -Path $gitDir -ChildPath 'config'
                    $configContent = @"
[core]
repositoryformatversion = 0
filemode = false
bare = false
logallrefupdates = true
symlinks = false
ignorecase = true
[remote "origin"]
url = $RemoteUrl
fetch = +refs/heads/*:refs/remotes/origin/*
"@
                    Set-Content -Path $configPath -Value $configContent -Encoding UTF8

                    $headPath = Join-Path -Path $gitDir -ChildPath 'HEAD'
                    Set-Content -Path $headPath -Value 'ref: refs/heads/main' -Encoding UTF8

                    $refsHeadsDir = Join-Path -Path $gitDir -ChildPath 'refs\heads'
                    New-Item -Path $refsHeadsDir -ItemType Directory -Force | Out-Null

                    $mainRefPath = Join-Path -Path $refsHeadsDir -ChildPath 'main'
                    Set-Content -Path $mainRefPath -Value 'a1b2c3d4e5f6g7h8i9j0k1l2m3n4o5p6q7r8s9t0' -Encoding UTF8

                    $testDate = Get-Date '2025-01-15 14:30:00'
                    (Get-Item -Path $mainRefPath).LastWriteTime = $testDate
                }

                $script:TestRepoForDate = Join-Path -Path $script:TestRoot -ChildPath 'RepoForDate'
                New-MockGitRepository -Path $script:TestRepoForDate -UserName 'Test' -UserEmail 'test@example.com'
            }

            AfterAll {
                if (Test-Path $script:TestRoot) {
                    Remove-Item -Path $script:TestRoot -Recurse -Force -ErrorAction SilentlyContinue
                }
            }

            It 'Should extract StatusDate from repository HEAD reference' {
                $statusDate = Get-DevDirectoryStatusDate -RepositoryPath $script:TestRepoForDate
                $statusDate | Should -Not -BeNullOrEmpty
                $statusDate | Should -BeOfType [datetime]
            }

            It 'Should return datetime from main branch ref file modification time' {
                $expectedDate = Get-Date '2025-01-15 14:30:00'
                $statusDate = Get-DevDirectoryStatusDate -RepositoryPath $script:TestRepoForDate

                # Allow 2 second tolerance for file system timing.
                $dateDiff = [Math]::Abs(($statusDate - $expectedDate).TotalSeconds)
                $dateDiff | Should -BeLessThan 2
            }

            It 'Should fall back to .git folder modification time when HEAD is unavailable' {
                $testRepo = Join-Path -Path $script:TestRoot -ChildPath 'RepoNoHead'
                $gitDir = Join-Path -Path $testRepo -ChildPath '.git'
                New-Item -Path $gitDir -ItemType Directory -Force | Out-Null

                $configPath = Join-Path -Path $gitDir -ChildPath 'config'
                Set-Content -Path $configPath -Value '[core]' -Encoding UTF8

                $statusDate = Get-DevDirectoryStatusDate -RepositoryPath $testRepo
                $statusDate | Should -Not -BeNullOrEmpty
                $statusDate | Should -BeOfType [datetime]
            }

            It 'Should handle non-existent repository path gracefully' {
                $nonExistentPath = Join-Path -Path $script:TestRoot -ChildPath 'NonExistentRepo'
                $statusDate = Get-DevDirectoryStatusDate -RepositoryPath $nonExistentPath
                $statusDate | Should -BeNullOrEmpty
            }

            It 'Should return HEAD LastWriteTime for detached head' {
                $testRepo = Join-Path -Path $script:TestRoot -ChildPath 'RepoDetached'
                $gitDir = Join-Path -Path $testRepo -ChildPath '.git'
                New-Item -Path $gitDir -ItemType Directory -Force | Out-Null

                $headPath = Join-Path $gitDir 'HEAD'
                Set-Content -LiteralPath $headPath -Value '1234567890abcdef1234567890abcdef12345678' -Encoding UTF8

                $known = (Get-Date).AddMinutes(-2)
                (Get-Item -LiteralPath $headPath).LastWriteTime = $known

                $date = Get-DevDirectoryStatusDate -RepositoryPath $testRepo

                # Allow tolerance.
                $dateDiff = [Math]::Abs(($date - $known).TotalSeconds)
                $dateDiff | Should -BeLessThan 2
            }

        }

    }

}
