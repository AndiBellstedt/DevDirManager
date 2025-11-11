Describe "Get-DevDirectoryUserInfo" -Tag "InternalFunction", "Git" {
    BeforeAll {
        $script:repoRoot = Join-Path $TestDrive "RepoA"
        New-Item -ItemType Directory -Path $script:repoRoot -Force | Out-Null
        $gitDir = Join-Path $script:repoRoot ".git"
        New-Item -ItemType Directory -Path $gitDir -Force | Out-Null
    }

    Context "Config parsing" {
        It "Should return null values when config missing" {
            $result = Get-DevDirectoryUserInfo -RepositoryPath $script:repoRoot
            $result.UserName | Should -Be $null
            $result.UserEmail | Should -Be $null
        }

        It "Should parse user.name and user.email from [user] section" {
            $configPath = Join-Path $script:repoRoot ".git\config"
            @"
            [user]
                name = Example User
                email = user@example.com
"@ | Set-Content -LiteralPath $configPath -Encoding UTF8

            $result = Get-DevDirectoryUserInfo -RepositoryPath $script:repoRoot
            $result.UserName | Should -Be "Example User"
            $result.UserEmail | Should -Be "user@example.com"
        }

        It "Should ignore global sections and only parse [user]" {
            $configPath = Join-Path $script:repoRoot ".git\config"
            @"
            [core]
                repositoryformatversion = 0
            [user]
                name = Example User2
                email = user2@example.com
            [remote "origin"]
                url = https://example/repo.git
"@ | Set-Content -LiteralPath $configPath -Encoding UTF8

            $result = Get-DevDirectoryUserInfo -RepositoryPath $script:repoRoot
            $result.UserName | Should -Be "Example User2"
            $result.UserEmail | Should -Be "user2@example.com"
        }

        It "Should handle missing email" {
            $configPath = Join-Path $script:repoRoot ".git\config"
            @"
            [user]
                name = Solo User
"@ | Set-Content -LiteralPath $configPath -Encoding UTF8

            $result = Get-DevDirectoryUserInfo -RepositoryPath $script:repoRoot
            $result.UserName | Should -Be "Solo User"
            $result.UserEmail | Should -Be $null
        }
    }
}
