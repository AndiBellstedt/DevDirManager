<!-- markdownlint-disable MD041 -->
# ![logo](assets/DevDirManager_128x128.png) DevDirManager - PowerShell Module for Managing Development Directory Repositories

| Platform           | Information                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                            |
| ------------------ | ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| PowerShell Gallery | [![PowerShell Gallery Version](https://img.shields.io/powershellgallery/v/DevDirManager)](https://www.powershellgallery.com/packages/DevDirManager) [![PowerShell Gallery](https://img.shields.io/powershellgallery/dt/DevDirManager)](https://www.powershellgallery.com/packages/DevDirManager) [![PowerShell Gallery Platform](https://img.shields.io/powershellgallery/p/DevDirManager)](https://www.powershellgallery.com/packages/DevDirManager)                                                                                                                                                                  |
| GitHub             | [![GitHub release](https://img.shields.io/github/v/release/AndiBellstedt/DevDirManager)](https://github.com/AndiBellstedt/DevDirManager/releases) [![GitHub](https://img.shields.io/github/license/AndiBellstedt/DevDirManager)](https://github.com/AndiBellstedt/DevDirManager/blob/main/LICENSE) ![GitHub issues](https://img.shields.io/github/issues-raw/AndiBellstedt/DevDirManager) ![GitHub last commit (branch)](https://img.shields.io/github/last-commit/AndiBellstedt/DevDirManager/main) ![GitHub last commit (branch)](https://img.shields.io/github/last-commit/AndiBellstedt/DevDirManager/Development) |

DevDirManager keeps local development folders in sync across machines. The module inventories every Git
repository beneath a directory, exports the structure to JSON or XML, restores repositories on another
computer, and even publishes or synchronises the inventory through a shared file or GitHub Gist. It is
designed for repeatable workstation setup when you maintain many repositories.

## Key Features
- Discover every Git repository below a root directory and record remote metadata.
- Export or import repository inventories in JSON or XML without losing folder hierarchy.
- Restore repositories with `git clone`, respecting existing folders via `-Force` or `-SkipExisting`.
- Publish or synchronise inventories so multiple machines stay aligned.

## How to Use DevDirManager

### Installation from PowerShell Gallery
```powershell
# Install the module from PowerShell Gallery (run as administrator if required)
PS C:\> Install-Module DevDirManager

# Import the module
PS C:\> Import-Module DevDirManager
PS C:\> $repositoryList = Get-DevDirectory -RootPath "C:\Dev"

# Export the inventory to JSON and keep it under version control or a gist
PS C:\> $repositoryList | Export-DevDirectoryList -Path "C:\Dev\repos.json"

# Restore the repositories on another machine in the same folder layout
PS C:\> Import-DevDirectoryList -Path "C:\Dev\repos.json" |
>> Restore-DevDirectory -DestinationPath "D:\Dev" -WhatIf

# Synchronise a directory with a shared inventory file
PS C:\> Sync-DevDirectoryList -DirectoryPath "C:\Dev" -RepositoryListPath "C:\Dev\repos.json" -PassThru

# Publish the latest inventory to a GitHub Gist (requires a gist-scoped token)
PS C:\> Publish-DevDirectoryList -Path "C:\Dev\repos.json" -AccessToken (Get-Secret "GitHubGistToken")
```

Use `-WhatIf` on `Restore-DevDirectory` and `Sync-DevDirectoryList` when previewing
changes, and combine the commands to keep your development environment reproducible across machines.
