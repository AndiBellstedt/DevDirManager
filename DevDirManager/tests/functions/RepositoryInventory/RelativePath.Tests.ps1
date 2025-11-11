Describe "RelativePath Formatting" -Tag "RelativePath", "PathFormatting" {
    BeforeAll {
        # Create a temporary directory structure for testing
        $script:TestRoot = Join-Path -Path $env:TEMP -ChildPath ([System.Guid]::NewGuid().ToString())
        New-Item -ItemType Directory -Path $script:TestRoot -Force | Out-Null

        # Create nested repository structures to test path formatting
        # Repository 1: At root level
        $script:RootRepo = Join-Path -Path $script:TestRoot -ChildPath "RootRepo"
        New-Item -ItemType Directory -Path "$script:RootRepo\.git" -Force | Out-Null

        # Repository 2: One level deep
        $script:OneLevelRepo = Join-Path -Path $script:TestRoot -ChildPath "Folder1\OneLevelRepo"
        New-Item -ItemType Directory -Path "$script:OneLevelRepo\.git" -Force | Out-Null

        # Repository 3: Two levels deep
        $script:TwoLevelRepo = Join-Path -Path $script:TestRoot -ChildPath "Folder1\Folder2\TwoLevelRepo"
        New-Item -ItemType Directory -Path "$script:TwoLevelRepo\.git" -Force | Out-Null

        # Repository 4: Three levels deep
        $script:ThreeLevelRepo = Join-Path -Path $script:TestRoot -ChildPath "Projects\WebApps\MyApp\ThreeLevelRepo"
        New-Item -ItemType Directory -Path "$script:ThreeLevelRepo\.git" -Force | Out-Null

        # Add remote config to each repo to avoid empty RemoteUrl issues
        foreach ($repoPath in @($script:RootRepo, $script:OneLevelRepo, $script:TwoLevelRepo, $script:ThreeLevelRepo)) {
            $gitConfig = Join-Path $repoPath ".git\config"
            $configContent = @"
[core]
    repositoryformatversion = 0
[remote "origin"]
    url = https://github.com/test/repo.git
    fetch = +refs/heads/*:refs/remotes/origin/*
"@
            Set-Content -Path $gitConfig -Value $configContent -Force
        }
    }

    AfterAll {
        # Cleanup
        if (Test-Path $script:TestRoot) {
            Remove-Item -Path $script:TestRoot -Recurse -Force -ErrorAction SilentlyContinue
        }
    }

    Context "Single Backslash in RelativePath" {
        It "Should use single backslashes, not double backslashes in RelativePath" {
            $repos = @(Get-DevDirectory -RootPath $script:TestRoot -SkipRemoteCheck)
            $repos.Count | Should -BeGreaterThan 0

            foreach ($repo in $repos) {
                # Check that RelativePath does not contain double backslashes
                $repo.RelativePath | Should -Not -Match '\\\\\\\\'

                # Verify we can split on single backslash
                if ($repo.RelativePath -ne '.') {
                    $parts = $repo.RelativePath -split '\\'
                    $parts.Count | Should -BeGreaterThan 0
                }
            }
        }

        It "Should have exactly one backslash between path segments in nested paths" {
            $repos = @(Get-DevDirectory -RootPath $script:TestRoot -SkipRemoteCheck)

            # Find the three-level deep repo
            $deepRepo = $repos | Where-Object { $_.FullPath -like "*Projects*WebApps*MyApp*" }
            $deepRepo | Should -Not -BeNullOrEmpty

            # Expected: "Projects\WebApps\MyApp\ThreeLevelRepo"
            # Should have exactly 3 backslashes (between 4 segments)
            $backslashCount = ($deepRepo.RelativePath.ToCharArray() | Where-Object { $_ -eq '\' }).Count
            $backslashCount | Should -Be 3

            # Verify no double backslashes
            $deepRepo.RelativePath | Should -Not -Match '\\\\\\\\'
        }

        It "Should correctly format single-level nested path" {
            $repos = @(Get-DevDirectory -RootPath $script:TestRoot -SkipRemoteCheck)

            $oneLevelRepo = $repos | Where-Object { $_.FullPath -like "*Folder1\OneLevelRepo*" }
            $oneLevelRepo | Should -Not -BeNullOrEmpty

            # Should be "Folder1\OneLevelRepo" with exactly 1 backslash
            $backslashCount = ($oneLevelRepo.RelativePath.ToCharArray() | Where-Object { $_ -eq '\' }).Count
            $backslashCount | Should -Be 1

            # Verify no double backslashes
            $oneLevelRepo.RelativePath | Should -Not -Match '\\\\\\\\'
        }

        It "Should correctly format two-level nested path" {
            $repos = @(Get-DevDirectory -RootPath $script:TestRoot -SkipRemoteCheck)

            $twoLevelRepo = $repos | Where-Object { $_.FullPath -like "*Folder1\Folder2\TwoLevelRepo*" }
            $twoLevelRepo | Should -Not -BeNullOrEmpty

            # Should be "Folder1\Folder2\TwoLevelRepo" with exactly 2 backslashes
            $backslashCount = ($twoLevelRepo.RelativePath.ToCharArray() | Where-Object { $_ -eq '\' }).Count
            $backslashCount | Should -Be 2

            # Verify no double backslashes
            $twoLevelRepo.RelativePath | Should -Not -Match '\\\\\\\\'
        }
    }

    Context "RelativePath Preservation Through Export/Import" {
        BeforeAll {
            $script:ExportPath = Join-Path -Path $script:TestRoot -ChildPath "path-test.json"
        }

        AfterAll {
            if (Test-Path $script:ExportPath) {
                Remove-Item -Path $script:ExportPath -Force
            }
        }

        It "Should preserve single backslashes in JSON export/import" {
            $originalRepos = @(Get-DevDirectory -RootPath $script:TestRoot -SkipRemoteCheck)
            $originalRepos | Export-DevDirectoryList -Path $script:ExportPath -Format JSON

            $importedRepos = @(Import-DevDirectoryList -Path $script:ExportPath)

            foreach ($imported in $importedRepos) {
                # Verify no double backslashes after import
                $imported.RelativePath | Should -Not -Match '\\\\\\\\'

                # Find matching original repo and compare
                $original = $originalRepos | Where-Object { $_.FullPath -eq $imported.FullPath }
                if ($original) {
                    $imported.RelativePath | Should -Be $original.RelativePath
                }
            }
        }

        It "Should preserve single backslashes in CSV export/import" {
            $csvPath = Join-Path -Path $script:TestRoot -ChildPath "path-test.csv"
            try {
                $originalRepos = @(Get-DevDirectory -RootPath $script:TestRoot -SkipRemoteCheck)
                $originalRepos | Export-DevDirectoryList -Path $csvPath -Format CSV

                $importedRepos = @(Import-DevDirectoryList -Path $csvPath)

                foreach ($imported in $importedRepos) {
                    # Verify no double backslashes after import
                    $imported.RelativePath | Should -Not -Match '\\\\\\\\'
                }
            } finally {
                if (Test-Path $csvPath) {
                    Remove-Item -Path $csvPath -Force
                }
            }
        }

        It "Should preserve single backslashes in XML export/import" {
            $xmlPath = Join-Path -Path $script:TestRoot -ChildPath "path-test.xml"
            try {
                $originalRepos = @(Get-DevDirectory -RootPath $script:TestRoot -SkipRemoteCheck)
                $originalRepos | Export-DevDirectoryList -Path $xmlPath -Format XML

                $importedRepos = @(Import-DevDirectoryList -Path $xmlPath)

                foreach ($imported in $importedRepos) {
                    # Verify no double backslashes after import
                    $imported.RelativePath | Should -Not -Match '\\\\\\\\'
                }
            } finally {
                if (Test-Path $xmlPath) {
                    Remove-Item -Path $xmlPath -Force
                }
            }
        }
    }

    Context "RelativePath Validation in Path Operations" {
        It "Should be able to reconstruct FullPath from RootPath and RelativePath" {
            $repos = @(Get-DevDirectory -RootPath $script:TestRoot -SkipRemoteCheck)

            foreach ($repo in $repos) {
                if ($repo.RelativePath -eq '.') {
                    # Root case
                    $reconstructed = $repo.RootPath
                } else {
                    # Join paths - should work with single backslashes
                    $reconstructed = Join-Path -Path $repo.RootPath -ChildPath $repo.RelativePath
                }

                # Normalize paths for comparison
                $reconstructed = $reconstructed.TrimEnd('\')
                $fullPath = $repo.FullPath.TrimEnd('\')

                $reconstructed | Should -Be $fullPath
            }
        }

        It "Should correctly split RelativePath into components" {
            $repos = @(Get-DevDirectory -RootPath $script:TestRoot -SkipRemoteCheck)

            # Get the three-level repo
            $deepRepo = $repos | Where-Object { $_.FullPath -like "*Projects*WebApps*MyApp*" }
            $deepRepo | Should -Not -BeNullOrEmpty

            # Split on single backslash should work correctly
            $parts = $deepRepo.RelativePath -split '\\'
            $parts.Count | Should -Be 4  # Projects, WebApps, MyApp, ThreeLevelRepo
            $parts[0] | Should -Be "Projects"
            $parts[1] | Should -Be "WebApps"
            $parts[2] | Should -Be "MyApp"
            $parts[3] | Should -Be "ThreeLevelRepo"
        }
    }

    Context "RelativePath Display Formatting" {
        It "Should display RelativePath with single backslashes in table format" {
            $repos = @(Get-DevDirectory -RootPath $script:TestRoot -SkipRemoteCheck)

            $tableOutput = $repos | Format-Table | Out-String -Width 400

            # Table output should not contain escaped or double backslashes
            # Verify that the output contains the RelativePath values
            $repos | ForEach-Object {
                if ($_.RelativePath -ne '.') {
                    $escapedPath = [regex]::Escape($_.RelativePath)
                    $tableOutput | Should -Match $escapedPath
                }
            }
        }

        It "Should display RelativePath with single backslashes in list format" {
            $repos = @(Get-DevDirectory -RootPath $script:TestRoot -SkipRemoteCheck)

            $listOutput = $repos | Format-List | Out-String

            # List output should contain the actual relative paths
            $listOutput | Should -Match "RelativePath"

            $repos | ForEach-Object {
                if ($_.RelativePath -ne '.') {
                    # The path should appear in the output
                    $escapedPath = [regex]::Escape($_.RelativePath)
                    $listOutput | Should -Match $escapedPath
                }
            }
        }
    }
}
