Describe 'Get-DevDirectoryUserInfo Internal Function' -Tag 'Unit', 'Internal' {

    InModuleScope 'DevDirManager' {

        Context "Parameter Contract" {

            BeforeAll {
                $command = Get-Command -Name 'Get-DevDirectoryUserInfo' -ErrorAction Stop
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

        BeforeAll {
            $script:TestRoot = Join-Path -Path $TestDrive -ChildPath 'UserInfoTests'
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

                if ($UserName -or $UserEmail) {
                    $configContent += "`n[user]`n"
                    if ($UserName) {
                        $configContent += "`tname = $UserName`n"
                    }
                    if ($UserEmail) {
                        $configContent += "`temail = $UserEmail`n"
                    }
                }

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

            $script:TestRepoWithUser = Join-Path -Path $script:TestRoot -ChildPath 'RepoWithUser'
            New-MockGitRepository -Path $script:TestRepoWithUser -UserName 'John Doe' -UserEmail 'john.doe@example.com'

            $script:TestRepoWithoutUser = Join-Path -Path $script:TestRoot -ChildPath 'RepoWithoutUser'
            New-MockGitRepository -Path $script:TestRepoWithoutUser
        }

        AfterAll {
            if (Test-Path $script:TestRoot) {
                Remove-Item -Path $script:TestRoot -Recurse -Force -ErrorAction SilentlyContinue
            }
        }

        Context 'User Configuration Extraction' {

            It 'Should extract UserName and UserEmail from repository with user config' {
                $userInfo = Get-DevDirectoryUserInfo -RepositoryPath $script:TestRepoWithUser
                $userInfo.UserName | Should -Be 'John Doe'
                $userInfo.UserEmail | Should -Be 'john.doe@example.com'
            }

            It 'Should return null values for repository without user config' {
                $userInfo = Get-DevDirectoryUserInfo -RepositoryPath $script:TestRepoWithoutUser
                $userInfo.UserName | Should -BeNullOrEmpty
                $userInfo.UserEmail | Should -BeNullOrEmpty
            }

            It 'Should handle repository with only UserName configured' {
                $testRepo = Join-Path -Path $script:TestRoot -ChildPath 'RepoUserNameOnly'
                New-MockGitRepository -Path $testRepo -UserName 'Jane Smith'
                $userInfo = Get-DevDirectoryUserInfo -RepositoryPath $testRepo
                $userInfo.UserName | Should -Be 'Jane Smith'
                $userInfo.UserEmail | Should -BeNullOrEmpty
            }

            It 'Should handle repository with only UserEmail configured' {
                $testRepo = Join-Path -Path $script:TestRoot -ChildPath 'RepoUserEmailOnly'
                New-MockGitRepository -Path $testRepo -UserEmail 'jane.smith@example.com'
                $userInfo = Get-DevDirectoryUserInfo -RepositoryPath $testRepo
                $userInfo.UserName | Should -BeNullOrEmpty
                $userInfo.UserEmail | Should -Be 'jane.smith@example.com'
            }

            It 'Should return hashtable with UserName and UserEmail keys' {
                $userInfo = Get-DevDirectoryUserInfo -RepositoryPath $script:TestRepoWithUser
                $userInfo | Should -BeOfType [hashtable]
                $userInfo.ContainsKey('UserName') | Should -Be $true
                $userInfo.ContainsKey('UserEmail') | Should -Be $true
            }
        }

        Context 'Edge Cases and Special Characters' {

            It 'Should handle UserName with spaces' {
                $testRepo = Join-Path -Path $script:TestRoot -ChildPath 'RepoSpaces'
                New-MockGitRepository -Path $testRepo -UserName 'John Q. Public' -UserEmail 'john@example.com'
                $userInfo = Get-DevDirectoryUserInfo -RepositoryPath $testRepo
                $userInfo.UserName | Should -Be 'John Q. Public'
            }

            It 'Should handle UserEmail with special characters' {
                $testRepo = Join-Path -Path $script:TestRoot -ChildPath 'RepoSpecialChars'
                New-MockGitRepository -Path $testRepo -UserName 'Test User' -UserEmail 'user+tag@example.co.uk'
                $userInfo = Get-DevDirectoryUserInfo -RepositoryPath $testRepo
                $userInfo.UserEmail | Should -Be 'user+tag@example.co.uk'
            }

            It 'Should handle non-existent repository path gracefully' {
                $nonExistentPath = Join-Path -Path $script:TestRoot -ChildPath 'NonExistent'
                $userInfo = Get-DevDirectoryUserInfo -RepositoryPath $nonExistentPath
                $userInfo.UserName | Should -BeNullOrEmpty
                $userInfo.UserEmail | Should -BeNullOrEmpty
            }

            It "Should ignore global sections and only parse [user]" {
                $testRepo = Join-Path -Path $script:TestRoot -ChildPath 'RepoGlobalSections'
                New-MockGitRepository -Path $testRepo
                $configPath = Join-Path $testRepo ".git\config"
                @"
            [core]
                repositoryformatversion = 0
            [user]
                name = Example User2
                email = user2@example.com
            [remote "origin"]
                url = https://example/repo.git
"@ | Set-Content -LiteralPath $configPath -Encoding UTF8

                $result = Get-DevDirectoryUserInfo -RepositoryPath $testRepo
                $result.UserName | Should -Be "Example User2"
                $result.UserEmail | Should -Be "user2@example.com"
            }

        }

    }

}
