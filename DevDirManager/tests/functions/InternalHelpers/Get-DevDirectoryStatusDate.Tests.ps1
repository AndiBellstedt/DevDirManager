Describe "Get-DevDirectoryStatusDate" -Tag "InternalFunction", "Git" {
    BeforeAll {
        $script:repoRoot = Join-Path $TestDrive "RepoStatus"
        New-Item -ItemType Directory -Path $script:repoRoot -Force | Out-Null
    }

    Context "Missing .git" {
        It "Should return null when .git folder absent" {
            Get-DevDirectoryStatusDate -RepositoryPath $script:repoRoot | Should -Be $null
        }
    }

    Context "Branch ref commit date" {
        BeforeAll {
            $gitDir = Join-Path $script:repoRoot ".git"
            New-Item -ItemType Directory -Path $gitDir -Force | Out-Null
            $headPath = Join-Path $gitDir "HEAD"
            Set-Content -LiteralPath $headPath -Value "ref: refs/heads/main" -Encoding UTF8
            $refsDir = Join-Path $gitDir "refs\heads"
            New-Item -ItemType Directory -Path $refsDir -Force | Out-Null
            $branchRef = Join-Path $refsDir "main"
            Set-Content -LiteralPath $branchRef -Value "1234567890abcdef1234567890abcdef12345678" -Encoding UTF8
            # Stamp branch ref file with known timestamp
            $known = (Get-Date).AddMinutes(-5)
            (Get-Item -LiteralPath $branchRef).LastWriteTime = $known
            $script:knownCommitDate = (Get-Item -LiteralPath $branchRef).LastWriteTime
        }
        It "Should return branch ref LastWriteTime" {
            $date = Get-DevDirectoryStatusDate -RepositoryPath $script:repoRoot
            $date | Should -Be $script:knownCommitDate
        }
    }

    Context "Detached HEAD" {
        BeforeAll {
            $gitDir = Join-Path $script:repoRoot ".git"
            New-Item -ItemType Directory -Path $gitDir -Force | Out-Null
            $headPath = Join-Path $gitDir "HEAD"
            Set-Content -LiteralPath $headPath -Value "1234567890abcdef1234567890abcdef12345678" -Encoding UTF8
            $known = (Get-Date).AddMinutes(-2)
            (Get-Item -LiteralPath $headPath).LastWriteTime = $known
            $script:detachedDate = (Get-Item -LiteralPath $headPath).LastWriteTime
        }
        It "Should return HEAD LastWriteTime for detached head" {
            $date = Get-DevDirectoryStatusDate -RepositoryPath $script:repoRoot
            $date | Should -Be $script:detachedDate
        }
    }

    Context ".git directory fallback" {
        BeforeAll {
            $gitDir = Join-Path $script:repoRoot ".git"
            New-Item -ItemType Directory -Path $gitDir -Force | Out-Null
            # Remove HEAD to force fallback
            $headPath = Join-Path $gitDir "HEAD"
            if (Test-Path -LiteralPath $headPath) { Remove-Item -LiteralPath $headPath -Force }
            $known = (Get-Date).AddMinutes(-1)
            (Get-Item -LiteralPath $gitDir).LastWriteTime = $known
            $script:fallbackDate = (Get-Item -LiteralPath $gitDir).LastWriteTime
        }
        It "Should return .git directory LastWriteTime when no commit info" {
            $date = Get-DevDirectoryStatusDate -RepositoryPath $script:repoRoot
            $date | Should -Be $script:fallbackDate
        }
    }
}
