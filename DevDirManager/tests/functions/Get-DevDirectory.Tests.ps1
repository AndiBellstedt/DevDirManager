Describe "Get-DevDirectory" -Tag "PublicFunction", "Core" {

    Context "Parameter Contract" {
        BeforeAll {
            $command = Get-Command -Name 'Get-DevDirectory'
            $parameters = $command.Parameters
        }

        Context "Parameter: RootPath" {
            BeforeAll { $p = $parameters['RootPath'] }
            It "Exists" { $p | Should -Not -BeNullOrEmpty }
            It "Is of type [string]" { $p.ParameterType.FullName | Should -Be 'System.String' }
            It "Is not Mandatory" { $p.Attributes.Where({$_ -is [System.Management.Automation.ParameterAttribute]}).Mandatory | Should -Not -Contain $true }
            It "Has ValidateNotNullOrEmpty" { $p.Attributes.Where({$_ -is [System.Management.Automation.ValidateNotNullOrEmptyAttribute]}) | Should -Not -BeNullOrEmpty }
        }

        Context "Parameter: SkipRemoteCheck" {
            BeforeAll { $p = $parameters['SkipRemoteCheck'] }
            It "Exists" { $p | Should -Not -BeNullOrEmpty }
            It "Is of type [switch]" { $p.ParameterType.FullName | Should -Be 'System.Management.Automation.SwitchParameter' }
            It "Is not Mandatory" { $p.Attributes.Where({$_ -is [System.Management.Automation.ParameterAttribute]}).Mandatory | Should -Not -Contain $true }
        }
    }

    BeforeAll {
        # Root for all Get-DevDirectory tests
        $script:TestRoot = Join-Path -Path $TestDrive -ChildPath 'GetDevDirectoryTests'
        New-Item -Path $script:TestRoot -ItemType Directory -Force | Out-Null

        # --- Setup for PSDrive Tests ---
        $script:PSDriveRoot = Join-Path -Path $script:TestRoot -ChildPath 'PSDriveRoot'
        New-Item -ItemType Directory -Path $script:PSDriveRoot -Force | Out-Null
        $script:PSDriveName = "DEVDIRMGR_GET_TEST"
        New-PSDrive -Name $script:PSDriveName -PSProvider FileSystem -Root $script:PSDriveRoot -Scope Global | Out-Null

        $script:RepoDir = Join-Path -Path $script:PSDriveRoot -ChildPath "TestRepo"
        New-Item -ItemType Directory -Path $script:RepoDir -Force | Out-Null
        $script:GitDir = Join-Path -Path $script:RepoDir -ChildPath ".git"
        New-Item -ItemType Directory -Path $script:GitDir -Force | Out-Null
        Set-Content -Path (Join-Path $script:GitDir "config") -Value "[core]`nrepositoryformatversion=0"

        # --- Setup for RelativePath Tests ---
        $script:RelativePathRoot = Join-Path -Path $script:TestRoot -ChildPath 'RelativePathRoot'
        New-Item -ItemType Directory -Path $script:RelativePathRoot -Force | Out-Null

        # Nested repos
        $script:RootRepo = Join-Path -Path $script:RelativePathRoot -ChildPath "RootRepo"
        New-Item -ItemType Directory -Path "$script:RootRepo\.git" -Force | Out-Null

        $script:OneLevelRepo = Join-Path -Path $script:RelativePathRoot -ChildPath "Folder1\OneLevelRepo"
        New-Item -ItemType Directory -Path "$script:OneLevelRepo\.git" -Force | Out-Null

        $script:TwoLevelRepo = Join-Path -Path $script:RelativePathRoot -ChildPath "Folder1\Folder2\TwoLevelRepo"
        New-Item -ItemType Directory -Path "$script:TwoLevelRepo\.git" -Force | Out-Null

        $script:ThreeLevelRepo = Join-Path -Path $script:RelativePathRoot -ChildPath "Projects\WebApps\MyApp\ThreeLevelRepo"
        New-Item -ItemType Directory -Path "$script:ThreeLevelRepo\.git" -Force | Out-Null

        foreach ($repoPath in @($script:RootRepo, $script:OneLevelRepo, $script:TwoLevelRepo, $script:ThreeLevelRepo)) {
            $gitConfig = Join-Path $repoPath ".git\config"
            Set-Content -Path $gitConfig -Value "[core]`nrepositoryformatversion=0`n[remote `"origin`"]`nurl=https://github.com/test/repo.git" -Force
        }

        # --- Setup for Remote Accessibility Tests ---
        $script:RemoteRoot = Join-Path -Path $script:TestRoot -ChildPath 'RemoteRoot'
        New-Item -ItemType Directory -Path $script:RemoteRoot -Force | Out-Null

        $script:ValidRepoDir = Join-Path -Path $script:RemoteRoot -ChildPath "ValidRepo"
        New-Item -ItemType Directory -Path "$script:ValidRepoDir\.git" -Force | Out-Null
        Set-Content -Path (Join-Path "$script:ValidRepoDir\.git" "config") -Value "[core]`nrepositoryformatversion=0`n[remote `"origin`"]`nurl=https://github.com/PowerShell/PowerShell.git"

        $script:InvalidRepoDir = Join-Path -Path $script:RemoteRoot -ChildPath "InvalidRepo"
        New-Item -ItemType Directory -Path "$script:InvalidRepoDir\.git" -Force | Out-Null
        Set-Content -Path (Join-Path "$script:InvalidRepoDir\.git" "config") -Value "[core]`nrepositoryformatversion=0`n[remote `"origin`"]`nurl=https://github.com/nonexistent/repo.git"

        $script:NoRemoteRepoDir = Join-Path -Path $script:RemoteRoot -ChildPath "NoRemoteRepo"
        New-Item -ItemType Directory -Path "$script:NoRemoteRepoDir\.git" -Force | Out-Null
        Set-Content -Path (Join-Path "$script:NoRemoteRepoDir\.git" "config") -Value "[core]`nrepositoryformatversion=0"

        # --- Setup for User Identity Tests ---
        $script:UserRoot = Join-Path -Path $script:TestRoot -ChildPath 'UserRoot'
        New-Item -ItemType Directory -Path $script:UserRoot -Force | Out-Null

        function New-MockGitRepository {
            param([string]$Path, [string]$UserName, [string]$UserEmail)
            New-Item -ItemType Directory -Path "$Path\.git" -Force | Out-Null
            $conf = "[core]`nrepositoryformatversion=0`n[remote `"origin`"]`nurl=https://github.com/test/repo.git"
            if ($UserName -or $UserEmail) {
                $conf += "`n[user]"
                if ($UserName) { $conf += "`nname=$UserName" }
                if ($UserEmail) { $conf += "`nemail=$UserEmail" }
            }
            Set-Content -Path "$Path\.git\config" -Value $conf

            # Add HEAD and ref for StatusDate
            Set-Content -Path "$Path\.git\HEAD" -Value "ref: refs/heads/main"
            New-Item -ItemType Directory -Path "$Path\.git\refs\heads" -Force | Out-Null
            Set-Content -Path "$Path\.git\refs\heads\main" -Value "hash"
        }

        $script:RepoWithUser = Join-Path -Path $script:UserRoot -ChildPath 'Repo1'
        New-MockGitRepository -Path $script:RepoWithUser -UserName 'Alice' -UserEmail 'alice@test.com'

        $script:RepoWithoutUser = Join-Path -Path $script:UserRoot -ChildPath 'Repo2'
        New-MockGitRepository -Path $script:RepoWithoutUser
    }

    BeforeEach {
        Mock -CommandName Test-DevDirectoryRemoteAccessible -ModuleName DevDirManager -MockWith {
            param([string]$RemoteUrl)
            if ([string]::IsNullOrWhiteSpace($RemoteUrl)) { return $false }
            if ($RemoteUrl -like '*nonexistent*') { return $false }
            return $true
        }
    }

    AfterAll {
        if (Get-PSDrive -Name $script:PSDriveName -ErrorAction SilentlyContinue) {
            Remove-PSDrive -Name $script:PSDriveName -Force -ErrorAction SilentlyContinue
        }
    }

    Context "PSDrive Support" {
        It "Should resolve PSDrive path correctly" {
            $psdrivePath = "$($script:PSDriveName):\"
            { Get-DevDirectory -RootPath $psdrivePath } | Should -Not -Throw
        }

        It "Should find repositories using PSDrive path" {
            $psdrivePath = "$($script:PSDriveName):\"
            $repos = @(Get-DevDirectory -RootPath $psdrivePath)
            $repos.Count | Should -BeGreaterThan 0
        }

        It "Should return valid FullPath property when using PSDrive" {
            $psdrivePath = "$($script:PSDriveName):\"
            $repos = Get-DevDirectory -RootPath $psdrivePath
            $repos[0].FullPath | Should -Not -BeNullOrEmpty
            Test-Path -LiteralPath $repos[0].FullPath | Should -Be $true
        }

        It "Should handle PSDrive paths with subdirectories" {
            $subDir = Join-Path -Path $script:PSDriveRoot -ChildPath "SubFolder"
            New-Item -ItemType Directory -Path $subDir -Force | Out-Null
            $psdrivePath = "$($script:PSDriveName):\SubFolder"
            { Get-DevDirectory -RootPath $psdrivePath } | Should -Not -Throw
        }
    }

    Context "RelativePath Formatting" {
        It "Should use single backslashes, not double backslashes in RelativePath" {
            $repos = @(Get-DevDirectory -RootPath $script:RelativePathRoot -SkipRemoteCheck)
            foreach ($repo in $repos) {
                $repo.RelativePath | Should -Not -Match '\\\\\\\\'
            }
        }

        It "Should have exactly one backslash between path segments in nested paths" {
            $repos = @(Get-DevDirectory -RootPath $script:RelativePathRoot -SkipRemoteCheck)
            $deepRepo = $repos | Where-Object { $_.FullPath -like "*Projects*WebApps*MyApp*" }
            $backslashCount = ($deepRepo.RelativePath.ToCharArray() | Where-Object { $_ -eq '\' }).Count
            $backslashCount | Should -Be 3
        }

        It "Should be able to reconstruct FullPath from RootPath and RelativePath" {
            $repos = @(Get-DevDirectory -RootPath $script:RelativePathRoot -SkipRemoteCheck)
            foreach ($repo in $repos) {
                if ($repo.RelativePath -eq '.') {
                    $reconstructed = $repo.RootPath
                } else {
                    $reconstructed = Join-Path -Path $repo.RootPath -ChildPath $repo.RelativePath
                }
                $reconstructed.TrimEnd('\') | Should -Be $repo.FullPath.TrimEnd('\')
            }
        }
    }

    Context "Remote Accessibility" {
        It "Should return IsRemoteAccessible property by default" {
            $repos = @(Get-DevDirectory -RootPath $script:RemoteRoot)
            foreach ($repo in $repos) {
                $repo.PSObject.Properties.Match('IsRemoteAccessible').Count | Should -Be 1
            }
        }

        It "Should mark valid remote as accessible" {
            $repos = @(Get-DevDirectory -RootPath $script:RemoteRoot)
            $validRepo = $repos | Where-Object { $_.FullPath -eq $script:ValidRepoDir }
            $validRepo.IsRemoteAccessible | Should -BeTrue
        }

        It "Should mark invalid remote as inaccessible" {
            $repos = @(Get-DevDirectory -RootPath $script:RemoteRoot)
            $invalidRepo = $repos | Where-Object { $_.FullPath -eq $script:InvalidRepoDir }
            $invalidRepo.IsRemoteAccessible | Should -BeFalse
        }

        It "Should skip remote check when -SkipRemoteCheck is specified" {
            $repos = @(Get-DevDirectory -RootPath $script:RemoteRoot -SkipRemoteCheck)
            foreach ($repo in $repos) {
                $repo.IsRemoteAccessible | Should -BeNullOrEmpty
            }
        }
    }

    Context "User Identity and Status" {
        It "Should discover all repositories with UserName, UserEmail, and StatusDate properties" {
            $repositories = Get-DevDirectory -RootPath $script:UserRoot
            foreach ($repo in $repositories) {
                $repo.PSObject.Properties.Match('UserName').Count | Should -Be 1
                $repo.PSObject.Properties.Match('UserEmail').Count | Should -Be 1
                $repo.PSObject.Properties.Match('StatusDate').Count | Should -Be 1
            }
        }

        It "Should correctly extract UserName/Email" {
            $repositories = Get-DevDirectory -RootPath $script:UserRoot
            $repo1 = $repositories | Where-Object { $_.FullPath -eq $script:RepoWithUser }
            $repo1.UserName | Should -Be 'Alice'
            $repo1.UserEmail | Should -Be 'alice@test.com'

            $repo2 = $repositories | Where-Object { $_.FullPath -eq $script:RepoWithoutUser }
            $repo2.UserName | Should -BeNullOrEmpty
        }
    }

}
