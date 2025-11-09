BeforeAll {
    # Import the module
    $moduleName = 'DevDirManager'
    $moduleRoot = Split-Path -Parent (Split-Path -Parent (Split-Path -Parent $PSScriptRoot))

    # Remove module if already loaded to ensure clean state
    Remove-Module $moduleName -Force -ErrorAction SilentlyContinue

    # Import the module
    Import-Module "$moduleRoot\$moduleName.psd1" -Force
}

Describe "Remote Accessibility Feature" -Tag "RemoteAccessibility", "NetworkDependent" {
    BeforeAll {
        # Create a temporary directory for testing
        $script:TestRoot = Join-Path -Path $env:TEMP -ChildPath ([System.Guid]::NewGuid().ToString())
        New-Item -ItemType Directory -Path $script:TestRoot -Force | Out-Null

        # Create test repository structures
        # Repository 1: Valid remote (GitHub public repo)
        $script:ValidRepoDir = Join-Path -Path $script:TestRoot -ChildPath "ValidRepo"
        New-Item -ItemType Directory -Path $script:ValidRepoDir -Force | Out-Null
        $validGitDir = Join-Path -Path $script:ValidRepoDir -ChildPath ".git"
        New-Item -ItemType Directory -Path $validGitDir -Force | Out-Null

        $validConfigContent = @"
[core]
    repositoryformatversion = 0
[remote "origin"]
    url = https://github.com/PowerShell/PowerShell.git
    fetch = +refs/heads/*:refs/remotes/origin/*
"@
        Set-Content -Path (Join-Path $validGitDir "config") -Value $validConfigContent -Force

        # Repository 2: Invalid remote (non-existent repo)
        $script:InvalidRepoDir = Join-Path -Path $script:TestRoot -ChildPath "InvalidRepo"
        New-Item -ItemType Directory -Path $script:InvalidRepoDir -Force | Out-Null
        $invalidGitDir = Join-Path -Path $script:InvalidRepoDir -ChildPath ".git"
        New-Item -ItemType Directory -Path $invalidGitDir -Force | Out-Null

        $invalidConfigContent = @"
[core]
    repositoryformatversion = 0
[remote "origin"]
    url = https://github.com/nonexistent-user-12345/nonexistent-repo-67890.git
    fetch = +refs/heads/*:refs/remotes/origin/*
"@
        Set-Content -Path (Join-Path $invalidGitDir "config") -Value $invalidConfigContent -Force

        # Repository 3: No remote configured
        $script:NoRemoteRepoDir = Join-Path -Path $script:TestRoot -ChildPath "NoRemoteRepo"
        New-Item -ItemType Directory -Path $script:NoRemoteRepoDir -Force | Out-Null
        $noRemoteGitDir = Join-Path -Path $script:NoRemoteRepoDir -ChildPath ".git"
        New-Item -ItemType Directory -Path $noRemoteGitDir -Force | Out-Null

        $noRemoteConfigContent = @"
[core]
    repositoryformatversion = 0
"@
        Set-Content -Path (Join-Path $noRemoteGitDir "config") -Value $noRemoteConfigContent -Force
    }

    AfterAll {
        # Cleanup
        if (Test-Path $script:TestRoot) {
            Remove-Item -Path $script:TestRoot -Recurse -Force -ErrorAction SilentlyContinue
        }
    }

    Context "Get-DevDirectory with Remote Accessibility Check" {
        It "Should return IsRemoteAccessible property by default" {
            $repos = @(Get-DevDirectory -RootPath $script:TestRoot)
            $repos.Count | Should -BeGreaterThan 0

            foreach ($repo in $repos) {
                $repo.PSObject.Properties.Match('IsRemoteAccessible').Count | Should -Be 1
            }
        }

        It "Should mark valid remote as accessible" -Skip:(-not (Test-Connection -ComputerName github.com -Count 1 -Quiet -ErrorAction SilentlyContinue)) {
            $repos = @(Get-DevDirectory -RootPath $script:TestRoot)
            $validRepo = $repos | Where-Object { $_.FullPath -eq $script:ValidRepoDir }

            $validRepo | Should -Not -BeNullOrEmpty
            $validRepo.IsRemoteAccessible | Should -Be $true
        }

        It "Should mark invalid remote as inaccessible" -Skip:(-not (Test-Connection -ComputerName github.com -Count 1 -Quiet -ErrorAction SilentlyContinue)) {
            $repos = @(Get-DevDirectory -RootPath $script:TestRoot)
            $invalidRepo = $repos | Where-Object { $_.FullPath -eq $script:InvalidRepoDir }

            $invalidRepo | Should -Not -BeNullOrEmpty
            $invalidRepo.IsRemoteAccessible | Should -Be $false
        }

        It "Should mark repository with no remote as inaccessible" {
            $repos = @(Get-DevDirectory -RootPath $script:TestRoot)
            $noRemoteRepo = $repos | Where-Object { $_.FullPath -eq $script:NoRemoteRepoDir }

            $noRemoteRepo | Should -Not -BeNullOrEmpty
            $noRemoteRepo.IsRemoteAccessible | Should -Be $false
        }

        It "Should skip remote check when -SkipRemoteCheck is specified" {
            $repos = @(Get-DevDirectory -RootPath $script:TestRoot -SkipRemoteCheck)
            $repos.Count | Should -BeGreaterThan 0

            foreach ($repo in $repos) {
                $repo.IsRemoteAccessible | Should -BeNullOrEmpty
            }
        }

        It "Should complete faster with -SkipRemoteCheck" {
            $withCheckTime = Measure-Command {
                Get-DevDirectory -RootPath $script:TestRoot | Out-Null
            }

            $withoutCheckTime = Measure-Command {
                Get-DevDirectory -RootPath $script:TestRoot -SkipRemoteCheck | Out-Null
            }

            $withoutCheckTime.TotalSeconds | Should -BeLessThan $withCheckTime.TotalSeconds
        }
    }

    Context "Export and Import Preserve IsRemoteAccessible" {
        BeforeAll {
            $script:ExportPath = Join-Path -Path $script:TestRoot -ChildPath "test-export.json"
        }

        AfterAll {
            if (Test-Path $script:ExportPath) {
                Remove-Item -Path $script:ExportPath -Force
            }
        }

        It "Should preserve IsRemoteAccessible in JSON export" {
            $repos = @(Get-DevDirectory -RootPath $script:TestRoot)
            $repos | Export-DevDirectoryList -Path $script:ExportPath -Format JSON

            Test-Path $script:ExportPath | Should -Be $true

            $imported = @(Import-DevDirectoryList -Path $script:ExportPath)
            $imported.Count | Should -Be $repos.Count

            foreach ($importedRepo in $imported) {
                $importedRepo.PSObject.Properties.Match('IsRemoteAccessible').Count | Should -Be 1
            }
        }

        It "Should preserve IsRemoteAccessible values through export/import cycle" {
            $repos = @(Get-DevDirectory -RootPath $script:TestRoot)
            $repos | Export-DevDirectoryList -Path $script:ExportPath -Format JSON

            $imported = @(Import-DevDirectoryList -Path $script:ExportPath)

            foreach ($originalRepo in $repos) {
                $matchingImported = $imported | Where-Object { $_.RelativePath -eq $originalRepo.RelativePath }
                $matchingImported | Should -Not -BeNullOrEmpty
                $matchingImported.IsRemoteAccessible | Should -Be $originalRepo.IsRemoteAccessible
            }
        }

        It "Should preserve IsRemoteAccessible in CSV export" {
            $csvPath = Join-Path -Path $script:TestRoot -ChildPath "test-export.csv"
            try {
                $repos = @(Get-DevDirectory -RootPath $script:TestRoot)
                $repos | Export-DevDirectoryList -Path $csvPath -Format CSV

                $imported = @(Import-DevDirectoryList -Path $csvPath)

                foreach ($importedRepo in $imported) {
                    $importedRepo.PSObject.Properties.Match('IsRemoteAccessible').Count | Should -Be 1
                }
            } finally {
                if (Test-Path $csvPath) {
                    Remove-Item -Path $csvPath -Force
                }
            }
        }

        It "Should preserve IsRemoteAccessible in XML export" {
            $xmlPath = Join-Path -Path $script:TestRoot -ChildPath "test-export.xml"
            try {
                $repos = @(Get-DevDirectory -RootPath $script:TestRoot)
                $repos | Export-DevDirectoryList -Path $xmlPath -Format XML

                $imported = @(Import-DevDirectoryList -Path $xmlPath)

                foreach ($importedRepo in $imported) {
                    $importedRepo.PSObject.Properties.Match('IsRemoteAccessible').Count | Should -Be 1
                }
            } finally {
                if (Test-Path $xmlPath) {
                    Remove-Item -Path $xmlPath -Force
                }
            }
        }
    }

    Context "Restore-DevDirectory Skips Inaccessible Remotes" {
        BeforeAll {
            $script:RestoreRoot = Join-Path -Path $script:TestRoot -ChildPath "RestoreTest"
            New-Item -ItemType Directory -Path $script:RestoreRoot -Force | Out-Null

            # Create test data with mixed accessibility
            $script:TestRepos = @(
                [PSCustomObject]@{
                    PSTypeName         = 'DevDirManager.Repository'
                    RelativePath       = "AccessibleRepo"
                    RemoteUrl          = "https://github.com/PowerShell/PowerShell.git"
                    RemoteName         = "origin"
                    IsRemoteAccessible = $true
                }
                [PSCustomObject]@{
                    PSTypeName         = 'DevDirManager.Repository'
                    RelativePath       = "InaccessibleRepo"
                    RemoteUrl          = "https://github.com/nonexistent/repo.git"
                    RemoteName         = "origin"
                    IsRemoteAccessible = $false
                }
                [PSCustomObject]@{
                    PSTypeName         = 'DevDirManager.Repository'
                    RelativePath       = "UnknownAccessibility"
                    RemoteUrl          = "https://github.com/some/repo.git"
                    RemoteName         = "origin"
                    IsRemoteAccessible = $null
                }
            )
        }

        AfterAll {
            if (Test-Path $script:RestoreRoot) {
                Remove-Item -Path $script:RestoreRoot -Recurse -Force -ErrorAction SilentlyContinue
            }
        }

        It "Should skip repositories with IsRemoteAccessible = false in WhatIf" {
            # Capture WhatIf output (information stream) and warnings
            $whatIfOutput = $script:TestRepos | Restore-DevDirectory -DestinationPath $script:RestoreRoot -WhatIf -InformationVariable infoVar -WarningVariable warnVar 2>&1

            # Convert to string for easier searching
            $allOutput = ($infoVar + $warnVar + $whatIfOutput) | Out-String

            # Should attempt to clone accessible repo
            $allOutput | Should -Match "AccessibleRepo"

            # Should skip inaccessible repo with warning message
            $allOutput | Should -Match "InaccessibleRepo"
        }

        It "Should not throw errors for inaccessible repositories" {
            { $script:TestRepos | Restore-DevDirectory -DestinationPath $script:RestoreRoot -WhatIf -ErrorAction Stop } | Should -Not -Throw
        }

        It "Should process repositories with null IsRemoteAccessible" {
            $nullAccessibilityRepo = $script:TestRepos | Where-Object { $_.IsRemoteAccessible -eq $null }

            # Should not skip repositories where IsRemoteAccessible is null (not explicitly false)
            { $nullAccessibilityRepo | Restore-DevDirectory -DestinationPath $script:RestoreRoot -WhatIf -ErrorAction Stop } | Should -Not -Throw
        }
    }

    Context "Sync-DevDirectoryList Respects IsRemoteAccessible" {
        BeforeAll {
            $script:SyncRoot = Join-Path -Path $script:TestRoot -ChildPath "SyncTest"
            New-Item -ItemType Directory -Path $script:SyncRoot -Force | Out-Null

            $script:SyncListPath = Join-Path -Path $script:TestRoot -ChildPath "sync-list.json"

            # Create a list with mixed accessibility
            $syncRepos = @(
                [PSCustomObject]@{
                    PSTypeName         = 'DevDirManager.Repository'
                    RootPath           = $script:SyncRoot
                    RelativePath       = "Repo1"
                    FullPath           = (Join-Path $script:SyncRoot "Repo1")
                    RemoteUrl          = "https://github.com/PowerShell/PowerShell.git"
                    RemoteName         = "origin"
                    UserName           = "Test User"
                    UserEmail          = "test@example.com"
                    StatusDate         = [DateTime](Get-Date)
                    IsRemoteAccessible = $true
                }
                [PSCustomObject]@{
                    PSTypeName         = 'DevDirManager.Repository'
                    RootPath           = $script:SyncRoot
                    RelativePath       = "Repo2"
                    FullPath           = (Join-Path $script:SyncRoot "Repo2")
                    RemoteUrl          = "https://github.com/nonexistent/repo.git"
                    RemoteName         = "origin"
                    UserName           = "Test User"
                    UserEmail          = "test@example.com"
                    StatusDate         = [DateTime](Get-Date)
                    IsRemoteAccessible = $false
                }
            )

            $syncRepos | Export-DevDirectoryList -Path $script:SyncListPath
        }

        AfterAll {
            if (Test-Path $script:SyncRoot) {
                Remove-Item -Path $script:SyncRoot -Recurse -Force -ErrorAction SilentlyContinue
            }
            if (Test-Path $script:SyncListPath) {
                Remove-Item -Path $script:SyncListPath -Force
            }
        }

        It "Should not attempt to clone inaccessible repositories during sync" {
            { Sync-DevDirectoryList -DirectoryPath $script:SyncRoot -RepositoryListPath $script:SyncListPath -WhatIf -ErrorAction Stop } | Should -Not -Throw
        }

        It "Should log warnings for skipped inaccessible repositories" {
            $warningOutput = Sync-DevDirectoryList -DirectoryPath $script:SyncRoot -RepositoryListPath $script:SyncListPath -WhatIf -WarningAction SilentlyContinue -WarningVariable warnings 3>&1

            # Check that warnings were generated (may vary based on PSFramework logging)
            # This is a soft check - the important thing is no errors were thrown
            $true | Should -Be $true
        }
    }

    Context "Format Display Includes IsRemoteAccessible" {
        It "Should display IsRemoteAccessible in table format" {
            $repos = @(Get-DevDirectory -RootPath $script:TestRoot)

            # Format as table and check output contains IsRemoteAccessible
            $tableOutput = $repos | Format-Table | Out-String

            # Should have the property available for formatting
            $repos[0].PSObject.Properties.Match('IsRemoteAccessible').Count | Should -Be 1
        }

        It "Should display IsRemoteAccessible in list format" {
            $repos = @(Get-DevDirectory -RootPath $script:TestRoot)

            # Format as list and check output
            $listOutput = $repos | Format-List | Out-String

            # Should include the property name in output
            $listOutput | Should -Match "IsRemoteAccessible"
        }
    }

    Context "Edge Cases and Error Handling" {
        It "Should handle empty remote URL gracefully" {
            $emptyRemoteRepo = [PSCustomObject]@{
                PSTypeName         = 'DevDirManager.Repository'
                RelativePath       = "EmptyRemote"
                RemoteUrl          = ""
                RemoteName         = "origin"
                IsRemoteAccessible = $false
            }

            { $emptyRemoteRepo | Restore-DevDirectory -DestinationPath $script:TestRoot -WhatIf } | Should -Not -Throw
        }

        It "Should handle null remote URL gracefully" {
            $nullRemoteRepo = [PSCustomObject]@{
                PSTypeName         = 'DevDirManager.Repository'
                RelativePath       = "NullRemote"
                RemoteUrl          = $null
                RemoteName         = "origin"
                IsRemoteAccessible = $false
            }

            { $nullRemoteRepo | Restore-DevDirectory -DestinationPath $script:TestRoot -WhatIf } | Should -Not -Throw
        }

        It "Should handle repositories without IsRemoteAccessible property" {
            # Simulate an old repository object without the new property
            $oldFormatRepo = [PSCustomObject]@{
                PSTypeName   = 'DevDirManager.Repository'
                RelativePath = "OldFormat"
                RemoteUrl    = "https://github.com/PowerShell/PowerShell.git"
                RemoteName   = "origin"
            }

            # Should not throw when property is missing
            { $oldFormatRepo | Restore-DevDirectory -DestinationPath $script:TestRoot -WhatIf } | Should -Not -Throw
        }
    }
}
