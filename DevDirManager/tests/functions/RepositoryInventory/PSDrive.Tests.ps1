BeforeAll {
    # Import the module
    $moduleName = 'DevDirManager'
    $moduleRoot = Split-Path -Parent (Split-Path -Parent (Split-Path -Parent $PSScriptRoot))

    # Remove module if already loaded to ensure clean state
    Remove-Module $moduleName -Force -ErrorAction SilentlyContinue

    # Import the module
    Import-Module "$moduleRoot\$moduleName.psd1" -Force
}

Describe "PSDrive Path Support" -Tag "PSDrive", "PathResolution" {
    BeforeAll {
        # Create a temporary directory for testing
        $script:TestRoot = Join-Path -Path $env:TEMP -ChildPath ([System.Guid]::NewGuid().ToString())
        New-Item -ItemType Directory -Path $script:TestRoot -Force | Out-Null

        # Create a test PSDrive pointing to the temp location
        $script:PSDriveName = "DEVDIRMGR_TEST"
        New-PSDrive -Name $script:PSDriveName -PSProvider FileSystem -Root $script:TestRoot -Scope Global | Out-Null

        # Create test directory structure
        $script:RepoDir = Join-Path -Path $script:TestRoot -ChildPath "TestRepo"
        New-Item -ItemType Directory -Path $script:RepoDir -Force | Out-Null

        # Initialize a test git repository
        $script:GitDir = Join-Path -Path $script:RepoDir -ChildPath ".git"
        New-Item -ItemType Directory -Path $script:GitDir -Force | Out-Null

        # Create minimal git config
        $configContent = @"
[core]
    repositoryformatversion = 0
    filemode = false
    bare = false
[remote "origin"]
    url = https://github.com/test/repo.git
    fetch = +refs/heads/*:refs/remotes/origin/*
"@
        $configPath = Join-Path -Path $script:GitDir -ChildPath "config"
        Set-Content -Path $configPath -Value $configContent -Force

        # Create test repository list file
        $script:RepoListPath = Join-Path -Path $script:TestRoot -ChildPath "repos.json"
        $testRepos = @(
            [PSCustomObject]@{
                RelativePath = "TestRepo"
                FullPath     = $script:RepoDir
                RemoteName   = "origin"
                RemoteUrl    = "https://github.com/test/repo.git"
                UserName     = "Test User"
                UserEmail    = "test@example.com"
                StatusDate   = Get-Date
            }
        )
        $testRepos | Export-DevDirectoryList -Path $script:RepoListPath
    }

    AfterAll {
        # Clean up PSDrive
        if (Get-PSDrive -Name $script:PSDriveName -ErrorAction SilentlyContinue) {
            Remove-PSDrive -Name $script:PSDriveName -Force -ErrorAction SilentlyContinue
        }

        # Clean up test directory
        if (Test-Path -Path $script:TestRoot) {
            Remove-Item -Path $script:TestRoot -Recurse -Force -ErrorAction SilentlyContinue
        }
    }

    Context "Get-DevDirectory with PSDrive" {
        It "Should resolve PSDrive path correctly" {
            $psdrivePath = "$($script:PSDriveName):\"
            { Get-DevDirectory -RootPath $psdrivePath } | Should -Not -Throw
        }

        It "Should find repositories using PSDrive path" {
            $psdrivePath = "$($script:PSDriveName):\"
            $repos = @(Get-DevDirectory -RootPath $psdrivePath)
            $repos | Should -Not -BeNullOrEmpty
            $repos.Count | Should -BeGreaterThan 0
        }

        It "Should return valid FullPath property when using PSDrive" {
            $psdrivePath = "$($script:PSDriveName):\"
            $repos = Get-DevDirectory -RootPath $psdrivePath
            $repos[0].FullPath | Should -Not -BeNullOrEmpty
            Test-Path -LiteralPath $repos[0].FullPath | Should -Be $true
        }
    }

    Context "Export-DevDirectoryList with PSDrive" {
        It "Should export to PSDrive path without errors" {
            $repos = Get-DevDirectory -RootPath $script:TestRoot
            $exportPath = "$($script:PSDriveName):\export-test.json"

            { $repos | Export-DevDirectoryList -Path $exportPath } | Should -Not -Throw
        }

        It "Should create file in PSDrive location" {
            $repos = Get-DevDirectory -RootPath $script:TestRoot
            $exportPath = "$($script:PSDriveName):\export-test2.json"

            $repos | Export-DevDirectoryList -Path $exportPath

            # Test using the actual file system path
            $actualPath = Join-Path -Path $script:TestRoot -ChildPath "export-test2.json"
            Test-Path -LiteralPath $actualPath | Should -Be $true
        }

        It "Should handle PSDrive path with -WhatIf" {
            $repos = Get-DevDirectory -RootPath $script:TestRoot
            $exportPath = "$($script:PSDriveName):\whatif-test.json"

            { $repos | Export-DevDirectoryList -Path $exportPath -WhatIf -InformationAction SilentlyContinue } | Should -Not -Throw
        }
    }

    Context "Import-DevDirectoryList with PSDrive" {
        It "Should import from PSDrive path without errors" {
            $importPath = "$($script:PSDriveName):\repos.json"

            { Import-DevDirectoryList -Path $importPath } | Should -Not -Throw
        }

        It "Should return valid data when importing from PSDrive" {
            $importPath = "$($script:PSDriveName):\repos.json"

            $repos = @(Import-DevDirectoryList -Path $importPath)
            $repos | Should -Not -BeNullOrEmpty
            $repos.Count | Should -BeGreaterThan 0
        }
    }

    Context "Restore-DevDirectory with PSDrive" {
        BeforeAll {
            # Create a separate destination directory for restore tests
            $script:RestoreDir = Join-Path -Path $script:TestRoot -ChildPath "RestoreTarget"
            New-Item -ItemType Directory -Path $script:RestoreDir -Force | Out-Null
        }

        It "Should handle PSDrive as DestinationPath with -WhatIf" {
            $psdrivePath = "$($script:PSDriveName):\RestoreTarget"
            $repos = Import-DevDirectoryList -Path $script:RepoListPath

            { $repos | Restore-DevDirectory -DestinationPath $psdrivePath -WhatIf -InformationAction SilentlyContinue } | Should -Not -Throw
        }

        It "Should resolve PSDrive DestinationPath correctly in WhatIf output" {
            $psdrivePath = "$($script:PSDriveName):\RestoreTarget"
            $repos = Import-DevDirectoryList -Path $script:RepoListPath | Select-Object -First 1

            # Capture WhatIf output by suppressing -WhatIf and checking path resolution works
            # We just verify the command doesn't throw and processes the path correctly
            { $repos | Restore-DevDirectory -DestinationPath $psdrivePath -WhatIf -InformationAction SilentlyContinue } | Should -Not -Throw

            # The real test is that no error was thrown - this means the PSDrive path was resolved
        }
    }

    Context "Sync-DevDirectoryList with PSDrive" {
        It "Should handle PSDrive as DirectoryPath with -WhatIf" {
            $psdrivePath = "$($script:PSDriveName):\"
            $listPath = Join-Path -Path $script:TestRoot -ChildPath "sync-test.json"

            # Create empty list file for sync test
            @() | Export-DevDirectoryList -Path $listPath

            { Sync-DevDirectoryList -DirectoryPath $psdrivePath -RepositoryListPath $listPath -WhatIf -InformationAction SilentlyContinue } | Should -Not -Throw
        }

        It "Should resolve PSDrive DirectoryPath correctly" {
            $psdrivePath = "$($script:PSDriveName):\"
            $listPath = Join-Path -Path $script:TestRoot -ChildPath "sync-test2.json"

            # Create empty list file for sync test
            @() | Export-DevDirectoryList -Path $listPath

            # Should not throw and should process correctly
            { Sync-DevDirectoryList -DirectoryPath $psdrivePath -RepositoryListPath $listPath -WhatIf -InformationAction SilentlyContinue } | Should -Not -Throw
        }

        It "Should handle both PSDrive paths (DirectoryPath and RepositoryListPath)" {
            $psdriveDirPath = "$($script:PSDriveName):\"
            $psdriveListPath = "$($script:PSDriveName):\sync-both.json"

            # Create empty list file
            @() | Export-DevDirectoryList -Path $psdriveListPath

            { Sync-DevDirectoryList -DirectoryPath $psdriveDirPath -RepositoryListPath $psdriveListPath -WhatIf -InformationAction SilentlyContinue } | Should -Not -Throw
        }
    }

    Context "Publish-DevDirectoryList with PSDrive" {
        It "Should handle PSDrive path for input file with -WhatIf" {
            $psdrivePath = "$($script:PSDriveName):\repos.json"

            # Create a dummy secure string token
            $secureToken = ConvertTo-SecureString -String "dummy-token-12345" -AsPlainText -Force

            # This would require valid GitHub token, so we only test path resolution with WhatIf
            # The function should at least be able to resolve the path before processing
            { Publish-DevDirectoryList -Path $psdrivePath -AccessToken $secureToken -WhatIf -InformationAction SilentlyContinue } | Should -Not -Throw
        }
    }

    Context "Edge Cases with PSDrives" {
        It "Should handle PSDrive paths with subdirectories" {
            $subDir = Join-Path -Path $script:TestRoot -ChildPath "SubFolder"
            New-Item -ItemType Directory -Path $subDir -Force | Out-Null

            $psdrivePath = "$($script:PSDriveName):\SubFolder"
            { Get-DevDirectory -RootPath $psdrivePath } | Should -Not -Throw
        }

        It "Should handle mixed case PSDrive names" {
            $mixedCasePath = "$($script:PSDriveName.ToLower()):\"
            { Get-DevDirectory -RootPath $mixedCasePath } | Should -Not -Throw
        }

        It "Should handle PSDrive paths with trailing backslash" {
            $psdrivePathWithSlash = "$($script:PSDriveName):\"
            $psdrivePathWithoutSlash = "$($script:PSDriveName):"

            { Get-DevDirectory -RootPath $psdrivePathWithSlash } | Should -Not -Throw
            { Get-DevDirectory -RootPath $psdrivePathWithoutSlash } | Should -Not -Throw
        }
    }
}
