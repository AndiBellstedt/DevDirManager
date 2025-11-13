BeforeAll {
    # Create a temporary directory for test files
    $script:TestRoot = Join-Path -Path $TestDrive -ChildPath 'UserIdentityTests'
    New-Item -Path $script:TestRoot -ItemType Directory -Force | Out-Null

    # Helper function to create a mock Git repository with custom configuration
    function New-MockGitRepository {
        param(
            [string]$Path,
            [string]$UserName,
            [string]$UserEmail,
            [string]$RemoteUrl = 'https://github.com/test/repo.git'
        )

        # Create repository directory structure
        $gitDir = Join-Path -Path $Path -ChildPath '.git'
        New-Item -Path $gitDir -ItemType Directory -Force | Out-Null

        # Create config file with user section
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

        # Add user section if UserName or UserEmail is provided
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

        # Create HEAD file pointing to main branch
        $headPath = Join-Path -Path $gitDir -ChildPath 'HEAD'
        Set-Content -Path $headPath -Value 'ref: refs/heads/main' -Encoding UTF8

        # Create refs directory structure
        $refsHeadsDir = Join-Path -Path $gitDir -ChildPath 'refs\heads'
        New-Item -Path $refsHeadsDir -ItemType Directory -Force | Out-Null

        # Create main branch ref file
        $mainRefPath = Join-Path -Path $refsHeadsDir -ChildPath 'main'
        Set-Content -Path $mainRefPath -Value 'a1b2c3d4e5f6g7h8i9j0k1l2m3n4o5p6q7r8s9t0' -Encoding UTF8

        # Set modification time to a known date
        $testDate = Get-Date '2025-01-15 14:30:00'
        (Get-Item -Path $mainRefPath).LastWriteTime = $testDate
    }
}

Describe 'Get-DevDirectoryUserInfo Internal Function' -Tag 'Unit', 'Internal' {
    # Testing the internal helper directly to ensure consistent behaviour
    BeforeAll {
        # Create test repository with user configuration
        $script:TestRepoWithUser = Join-Path -Path $script:TestRoot -ChildPath 'RepoWithUser'
        New-MockGitRepository -Path $script:TestRepoWithUser -UserName 'John Doe' -UserEmail 'john.doe@example.com'

        # Create test repository without user configuration
        $script:TestRepoWithoutUser = Join-Path -Path $script:TestRoot -ChildPath 'RepoWithoutUser'
        New-MockGitRepository -Path $script:TestRepoWithoutUser
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
    }
}

Describe 'Get-DevDirectoryStatusDate Internal Function' -Tag 'Unit', 'Internal' {
    # Testing the internal helper directly to ensure consistent behaviour
    BeforeAll {
        # Create test repository with known modification date
        $script:TestRepoForDate = Join-Path -Path $script:TestRoot -ChildPath 'RepoForDate'
        New-MockGitRepository -Path $script:TestRepoForDate -UserName 'Test' -UserEmail 'test@example.com'
    }

    Context 'Status Date Extraction' {
        It 'Should extract StatusDate from repository HEAD reference' {
            $statusDate = Get-DevDirectoryStatusDate -RepositoryPath $script:TestRepoForDate
            $statusDate | Should -Not -BeNullOrEmpty
            $statusDate | Should -BeOfType [datetime]
        }

        It 'Should return datetime from main branch ref file modification time' {
            $expectedDate = Get-Date '2025-01-15 14:30:00'
            $statusDate = Get-DevDirectoryStatusDate -RepositoryPath $script:TestRepoForDate

            # Allow 1 second tolerance for file system timing
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
    }
}

Describe 'Get-DevDirectory New Properties Integration' -Tag 'Integration' {
    BeforeAll {
        Mock -CommandName Test-DevDirectoryRemoteAccessible -ModuleName DevDirManager -MockWith {
            param(
                [string]$RemoteUrl,
                [string]$GitExecutable,
                [int]$TimeoutSeconds
            )

            return -not [string]::IsNullOrWhiteSpace($RemoteUrl)
        }

        # Create test directory structure with multiple repositories
        $script:IntegrationTestRoot = Join-Path -Path $script:TestRoot -ChildPath 'Integration'
        New-Item -Path $script:IntegrationTestRoot -ItemType Directory -Force | Out-Null

        # Repository 1: Full user config
        $repo1Path = Join-Path -Path $script:IntegrationTestRoot -ChildPath 'Repo1'
        New-MockGitRepository -Path $repo1Path -UserName 'Alice Johnson' -UserEmail 'alice@company.com'

        # Repository 2: Partial user config
        $repo2Path = Join-Path -Path $script:IntegrationTestRoot -ChildPath 'Repo2'
        New-MockGitRepository -Path $repo2Path -UserName 'Bob Smith'

        # Repository 3: No user config
        $repo3Path = Join-Path -Path $script:IntegrationTestRoot -ChildPath 'Repo3'
        New-MockGitRepository -Path $repo3Path
    }

    Context 'Repository Discovery with New Properties' {
        It 'Should discover all repositories with UserName, UserEmail, and StatusDate properties' {
            $repositories = Get-DevDirectory -RootPath $script:IntegrationTestRoot
            $repositories.Count | Should -Be 3

            foreach ($repo in $repositories) {
                # Verify new properties exist
                $repo.PSObject.Properties.Match('UserName').Count | Should -Be 1
                $repo.PSObject.Properties.Match('UserEmail').Count | Should -Be 1
                $repo.PSObject.Properties.Match('StatusDate').Count | Should -Be 1
            }
        }

        It 'Should correctly extract UserName for repositories with user.name configured' {
            $repositories = Get-DevDirectory -RootPath $script:IntegrationTestRoot
            $repo1 = $repositories | Where-Object { $_.RelativePath -eq 'Repo1' }
            $repo1.UserName | Should -Be 'Alice Johnson'

            $repo2 = $repositories | Where-Object { $_.RelativePath -eq 'Repo2' }
            $repo2.UserName | Should -Be 'Bob Smith'
        }

        It 'Should correctly extract UserEmail for repositories with user.email configured' {
            $repositories = Get-DevDirectory -RootPath $script:IntegrationTestRoot
            $repo1 = $repositories | Where-Object { $_.RelativePath -eq 'Repo1' }
            $repo1.UserEmail | Should -Be 'alice@company.com'

            $repo2 = $repositories | Where-Object { $_.RelativePath -eq 'Repo2' }
            $repo2.UserEmail | Should -BeNullOrEmpty
        }

        It 'Should extract StatusDate as datetime for all repositories' {
            $repositories = Get-DevDirectory -RootPath $script:IntegrationTestRoot
            foreach ($repo in $repositories) {
                if ($repo.StatusDate) {
                    $repo.StatusDate | Should -BeOfType [datetime]
                }
            }
        }

        It 'Should preserve existing properties (RemoteName, RemoteUrl, etc.)' {
            $repositories = Get-DevDirectory -RootPath $script:IntegrationTestRoot
            foreach ($repo in $repositories) {
                $repo.RemoteName | Should -Be 'origin'
                $repo.RemoteUrl | Should -Be 'https://github.com/test/repo.git'
                $repo.RootPath | Should -Not -BeNullOrEmpty
                $repo.RelativePath | Should -Not -BeNullOrEmpty
                $repo.FullPath | Should -Not -BeNullOrEmpty
            }
        }
    }
}

Describe 'Export-DevDirectoryList and Import-DevDirectoryList New Properties' -Tag 'Integration', 'Format' {
    BeforeAll {
        Mock -CommandName Test-DevDirectoryRemoteAccessible -ModuleName DevDirManager -MockWith {
            param(
                [string]$RemoteUrl,
                [string]$GitExecutable,
                [int]$TimeoutSeconds
            )

            return -not [string]::IsNullOrWhiteSpace($RemoteUrl)
        }

        # Create test repositories with new properties
        $script:FormatTestRoot = Join-Path -Path $script:TestRoot -ChildPath 'FormatTests'
        New-Item -Path $script:FormatTestRoot -ItemType Directory -Force | Out-Null

        $repoPath = Join-Path -Path $script:FormatTestRoot -ChildPath 'TestRepo'
        New-MockGitRepository -Path $repoPath -UserName 'Test Author' -UserEmail 'author@test.com'

        # Get repositories with new properties
        $script:RepositoriesWithNewProperties = Get-DevDirectory -RootPath $script:FormatTestRoot
    }

    Context 'CSV Format with New Properties' {
        BeforeAll {
            $script:CsvPath = Join-Path -Path $script:TestRoot -ChildPath 'repos-with-properties.csv'
        }

        It 'Should export repositories with UserName, UserEmail, and StatusDate to CSV' {
            $script:RepositoriesWithNewProperties | Export-DevDirectoryList -Path $script:CsvPath -Format CSV
            $script:CsvPath | Should -Exist

            $csvContent = Get-Content -Path $script:CsvPath -Raw
            $csvContent | Should -Match 'UserName'
            $csvContent | Should -Match 'UserEmail'
            $csvContent | Should -Match 'StatusDate'
        }

        It 'Should import repositories from CSV and preserve UserName, UserEmail, and StatusDate' {
            $importedRepos = Import-DevDirectoryList -Path $script:CsvPath -Format CSV
            $importedRepos.Count | Should -Be $script:RepositoriesWithNewProperties.Count

            foreach ($repo in $importedRepos) {
                $repo.PSObject.Properties.Match('UserName').Count | Should -Be 1
                $repo.PSObject.Properties.Match('UserEmail').Count | Should -Be 1
                $repo.PSObject.Properties.Match('StatusDate').Count | Should -Be 1
            }
        }

        It 'Should preserve UserName value after CSV round-trip' {
            $importedRepos = Import-DevDirectoryList -Path $script:CsvPath -Format CSV
            $importedRepos[0].UserName | Should -Be 'Test Author'
        }

        It 'Should preserve UserEmail value after CSV round-trip' {
            $importedRepos = Import-DevDirectoryList -Path $script:CsvPath -Format CSV
            $importedRepos[0].UserEmail | Should -Be 'author@test.com'
        }

        It 'Should preserve StatusDate value after CSV round-trip' {
            $importedRepos = Import-DevDirectoryList -Path $script:CsvPath -Format CSV
            if ($importedRepos[0].StatusDate) {
                $importedRepos[0].StatusDate | Should -BeOfType [datetime]
            }
        }
    }

    Context 'JSON Format with New Properties' {
        BeforeAll {
            $script:JsonPath = Join-Path -Path $script:TestRoot -ChildPath 'repos-with-properties.json'
        }

        It 'Should export repositories with UserName, UserEmail, and StatusDate to JSON' {
            $script:RepositoriesWithNewProperties | Export-DevDirectoryList -Path $script:JsonPath -Format JSON
            $script:JsonPath | Should -Exist

            $jsonContent = Get-Content -Path $script:JsonPath -Raw
            $jsonContent | Should -Match '"UserName"'
            $jsonContent | Should -Match '"UserEmail"'
            $jsonContent | Should -Match '"StatusDate"'
        }

        It 'Should import repositories from JSON and preserve new properties' {
            $importedRepos = Import-DevDirectoryList -Path $script:JsonPath -Format JSON
            $importedRepos.Count | Should -Be $script:RepositoriesWithNewProperties.Count

            foreach ($repo in $importedRepos) {
                $repo.PSObject.Properties.Match('UserName').Count | Should -Be 1
                $repo.PSObject.Properties.Match('UserEmail').Count | Should -Be 1
                $repo.PSObject.Properties.Match('StatusDate').Count | Should -Be 1
            }
        }

        It 'Should preserve property values after JSON round-trip' {
            $importedRepos = Import-DevDirectoryList -Path $script:JsonPath -Format JSON
            $importedRepos[0].UserName | Should -Be 'Test Author'
            $importedRepos[0].UserEmail | Should -Be 'author@test.com'
        }
    }

    Context 'XML Format with New Properties' {
        BeforeAll {
            $script:XmlPath = Join-Path -Path $script:TestRoot -ChildPath 'repos-with-properties.xml'
        }

        It 'Should export repositories with UserName, UserEmail, and StatusDate to XML' {
            $script:RepositoriesWithNewProperties | Export-DevDirectoryList -Path $script:XmlPath -Format XML
            $script:XmlPath | Should -Exist

            $xmlContent = Get-Content -Path $script:XmlPath -Raw
            # PowerShell CliXML uses <S N="PropertyName"> format for string properties
            $xmlContent | Should -Match '<S N="UserName"'
            $xmlContent | Should -Match '<S N="UserEmail"'
            # DateTime properties use <DT N="PropertyName"> format
            $xmlContent | Should -Match '<DT N="StatusDate"'
        }

        It 'Should import repositories from XML and preserve type information' {
            $importedRepos = Import-DevDirectoryList -Path $script:XmlPath -Format XML
            $importedRepos.Count | Should -Be $script:RepositoriesWithNewProperties.Count

            foreach ($repo in $importedRepos) {
                $repo.PSObject.TypeNames | Should -Contain 'DevDirManager.Repository'
            }
        }

        It 'Should preserve property values after XML round-trip' {
            $importedRepos = Import-DevDirectoryList -Path $script:XmlPath -Format XML
            $importedRepos[0].UserName | Should -Be 'Test Author'
            $importedRepos[0].UserEmail | Should -Be 'author@test.com'
            if ($importedRepos[0].StatusDate) {
                $importedRepos[0].StatusDate | Should -BeOfType [datetime]
            }
        }
    }
}

Describe 'Sync-DevDirectoryList Property Merge Logic' -Tag 'Integration' {
    BeforeAll {
        Mock -CommandName Test-DevDirectoryRemoteAccessible -ModuleName DevDirManager -MockWith {
            param(
                [string]$RemoteUrl,
                [string]$GitExecutable,
                [int]$TimeoutSeconds
            )

            return -not [string]::IsNullOrWhiteSpace($RemoteUrl)
        }

        # Create directory for sync tests
        $script:SyncTestRoot = Join-Path -Path $script:TestRoot -ChildPath 'SyncTests'
        New-Item -Path $script:SyncTestRoot -ItemType Directory -Force | Out-Null

        # Create a repository with user config
        $repoPath = Join-Path -Path $script:SyncTestRoot -ChildPath 'MergeRepo'
        New-MockGitRepository -Path $repoPath -UserName 'Local User' -UserEmail 'local@example.com'

        # Create a repository list file with different user info
        $script:SyncListPath = Join-Path -Path $script:TestRoot -ChildPath 'sync-repos.json'
        $fileRepos = @(
            [PSCustomObject]@{
                PSTypeName   = 'DevDirManager.Repository'
                RootPath     = $script:SyncTestRoot
                RelativePath = 'MergeRepo'
                FullPath     = $repoPath
                RemoteName   = 'origin'
                RemoteUrl    = 'https://github.com/test/repo.git'
                UserName     = 'File User'
                UserEmail    = 'file@example.com'
                StatusDate   = (Get-Date).AddDays(-30)
            }
        )
        $fileRepos | Export-DevDirectoryList -Path $script:SyncListPath -Format JSON
    }

    Context 'Property Merge Behavior' {
        It 'Should prefer local UserName over file UserName during sync' {
            $result = Sync-DevDirectoryList -DirectoryPath $script:SyncTestRoot -RepositoryListPath $script:SyncListPath -PassThru -WhatIf -InformationAction SilentlyContinue
            $result | Should -Not -BeNullOrEmpty

            $mergeRepo = $result | Where-Object { $_.RelativePath -eq 'MergeRepo' }
            $mergeRepo | Should -Not -BeNullOrEmpty
            $mergeRepo.UserName | Should -Be 'Local User'
        }

        It 'Should prefer local UserEmail over file UserEmail during sync' {
            $result = Sync-DevDirectoryList -DirectoryPath $script:SyncTestRoot -RepositoryListPath $script:SyncListPath -PassThru -WhatIf -InformationAction SilentlyContinue
            $result | Should -Not -BeNullOrEmpty

            $mergeRepo = $result | Where-Object { $_.RelativePath -eq 'MergeRepo' }
            $mergeRepo | Should -Not -BeNullOrEmpty
            $mergeRepo.UserEmail | Should -Be 'local@example.com'
        }
    }
}

AfterAll {
    # Clean up test directory
    if (Test-Path -Path $script:TestRoot) {
        Remove-Item -Path $script:TestRoot -Recurse -Force -ErrorAction SilentlyContinue
    }
}
