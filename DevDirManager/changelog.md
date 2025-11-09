# Changelog

## [Unreleased]

### Added
- **Remote Accessibility Tracking Feature**
  - Added `IsRemoteAccessible` property to track whether repository remote URLs are accessible
  - `Get-DevDirectory` now checks remote accessibility by default using `git ls-remote` with timeout
  - New `-SkipRemoteCheck` parameter in `Get-DevDirectory` to disable remote checking for faster performance
  - Repositories with inaccessible remotes are marked with `IsRemoteAccessible = $false`
  - Property is preserved through export/import cycles (JSON, CSV, XML)
  - Created internal helper function `Test-DevDirectoryRemoteAccessible` for remote validation
- **Automatic Skipping of Inaccessible Repositories**
  - `Restore-DevDirectory` now skips cloning repositories marked as inaccessible
  - `Sync-DevDirectoryList` respects `IsRemoteAccessible` property and skips cloning inaccessible repos
  - Both functions log warnings when skipping repositories with inaccessible remotes
  - Prevents git clone failures for deleted, moved, or private repositories
- Added `IsRemoteAccessible` column to table and list format views
- Added localization strings for remote accessibility warnings
- Added comprehensive Pester tests for remote accessibility feature
  - Created `tests\functions\RepositoryInventory\RemoteAccessibility.Tests.ps1` with 20 test cases
  - Tests cover remote checking, export/import preservation, skip logic, format display, and edge cases
- Added comprehensive Pester tests for RelativePath formatting
  - Created `tests\functions\RepositoryInventory\RelativePath.Tests.ps1` with 15+ test cases
  - Tests ensure single backslashes in paths, proper path reconstruction, and format preservation through export/import
  - Prevents regression of double backslash issues in relative paths
- Updated function versions:
  - Get-DevDirectory: 1.2.1 → 1.3.2
  - Restore-DevDirectory: 1.2.1 → 1.3.0
  - Sync-DevDirectoryList: 1.2.2 → 1.3.0

### Fixed
- Fixed missing localization string `RestoreDevDirectory.ConfigFailed` for git config error messages
- Fixed CSV StatusDate type conversion issue
  - Import-DevDirectoryList now correctly parses StatusDate from CSV using try-catch with Parse() method
  - Resolves issue where CSV imports would leave StatusDate as string instead of DateTime on systems with non-US cultures
  - Fixed Windows PowerShell 5.1 compatibility issue with TryParse() method overloads
  - Updated function version: Import-DevDirectoryList: 1.2.1 → 1.2.2
- Fixed Windows PowerShell 5.1 compatibility in PSDrive tests
  - Updated tests to wrap function results in @() to ensure array handling works correctly in PowerShell 5.1
  - Resolves issue where .Count property returns $null for single objects in Windows PowerShell 5.1
- Fixed PSDrive path resolution in Sync-DevDirectoryList and Export-DevDirectoryList
  - Now properly resolves PSDrive paths (e.g., `GIT:\`, `TEMP:\`) to their actual file system paths
  - Fixes issue where PSDrive paths would cause incorrect WhatIf output and execution failures
  - Sync-DevDirectoryList updated to use `GetUnresolvedProviderPathFromPSPath` to handle non-existent paths (which is valid as the function can create directories)
  - Export-DevDirectoryList updated to resolve PSDrive paths before processing with `Split-Path`
  - Resolves issue where paths like `GIT:\RepoRestore` would be incorrectly combined with current directory
- Fixed remote accessibility check for repositories without remote URLs
  - Get-DevDirectory now properly handles repositories with empty or null remote URLs
  - Prevents validation errors when calling Test-DevDirectoryRemoteAccessible with empty RemoteUrl
  - Repositories without remotes are marked as inaccessible (IsRemoteAccessible = $false)
  - Updated function version: Get-DevDirectory: 1.3.0 → 1.3.1
- Fixed Windows PowerShell 5.1 compatibility in RemoteAccessibility tests
  - Fixed DateTime serialization issue in test data for Sync-DevDirectoryList tests
  - StatusDate property now explicitly cast to [DateTime] to prevent serialization issues in Windows PowerShell
  - Resolves "Cannot convert value to type System.DateTime" errors when importing test repository data
- Fixed double backslash issue in RelativePath property
  - Get-DevDirectory now uses `.Replace()` instead of `-replace` for path separator conversion
  - RelativePath now correctly uses single backslashes (e.g., `Project\Repo` instead of `Project\\Repo`)
  - Ensures paths can be properly split and reconstructed using standard PowerShell path operations
  - Fixes display and export issues where double backslashes appeared in relative paths
  - Updated function version: Get-DevDirectory: 1.3.1 → 1.3.2
- Updated function versions:
  - Sync-DevDirectoryList: 1.2.1 → 1.2.2
  - Export-DevDirectoryList: 1.2.1 → 1.2.2

### Added
- Added comprehensive Pester tests for PSDrive path support
  - Tests cover all public functions (Get-DevDirectory, Export-DevDirectoryList, Import-DevDirectoryList, Restore-DevDirectory, Sync-DevDirectoryList, Publish-DevDirectoryList)
  - Includes tests for WhatIf scenarios, mixed case PSDrive names, paths with subdirectories, and trailing backslashes
  - Created `tests\functions\RepositoryInventory\PSDrive.Tests.ps1` with 15+ test cases

### Changed - Code Refactoring (Part 2)
- Further refactored common code patterns into reusable internal components
  - Created `Resolve-RepositoryListFormat` internal function to handle file format inference from extensions (eliminates duplicate code across Export-DevDirectoryList, Import-DevDirectoryList, and Publish-DevDirectoryList)
  - Created `Add-RepositoryTypeName` internal function to add DevDirManager.Repository type name to PSObjects (eliminates repeated code within Import-DevDirectoryList)
  - Created `New-DirectoryIfNeeded` internal function for directory creation with existence checking (eliminates duplicate patterns across Export-DevDirectoryList, Restore-DevDirectory, and Sync-DevDirectoryList)
  - Moved unsafe path regex from configuration to script-level constant `$script:UnsafeRelativePathPattern` for security (prevents user misconfiguration)
- Updated function versions:
  - Export-DevDirectoryList: 1.2.0 → 1.2.1
  - Import-DevDirectoryList: 1.2.0 → 1.2.1
  - Publish-DevDirectoryList: 1.1.2 → 1.1.3

### Changed - Code Refactoring (Part 1)
- Refactored common code patterns into reusable internal components for better maintainability
  - Created `Resolve-NormalizedPath` internal function to handle path resolution and normalization (eliminates duplicate code across Get-DevDirectory, Restore-DevDirectory)
  - Improved code reusability and test coverage across the module
- Updated function versions:
  - Get-DevDirectory: 1.2.0 → 1.2.1
  - Restore-DevDirectory: 1.2.0 → 1.2.1
  - Sync-DevDirectoryList: 1.2.0 → 1.2.1

### Fixed
- Fixed security concern where unsafe path validation pattern was user-configurable through module configuration
  - Moved pattern to immutable script constant to prevent tampering

## [1.2.0] - 2025-10-31

### Added
- Enhanced repository metadata with user identity tracking
  - Added `UserName` property to capture repository-local git user.name configuration
  - Added `UserEmail` property to capture repository-local git user.email configuration
  - Added `StatusDate` property to track the most recent commit or repository activity date
- Git configuration synchronization in Restore-DevDirectory
  - When cloning repositories, if UserName and UserEmail are present in metadata, they are automatically configured in the cloned repository using `git config --local`
  - Ensures cloned repositories maintain the same user identity as the original repository

### Changed
- Updated Get-DevDirectory to extract and include UserName, UserEmail, and StatusDate properties for each discovered repository
- Updated Sync-DevDirectoryList merge logic to intelligently combine UserName, UserEmail, and StatusDate from both local repositories and repository list files
  - Local repository values are preferred over file values when both are present
  - Ensures metadata accuracy reflects the current state of local repositories
- Updated Export-DevDirectoryList and Import-DevDirectoryList to handle new properties through automatic serialization
- Updated Publish-DevDirectoryList to include new properties in published gists
- Enhanced New-DevDirectorySyncRecord internal helper to support new UserName, UserEmail, and StatusDate parameters
- Extended custom format views (table and list) to display new properties in console output

### Technical Notes
- All property extraction is based exclusively on repository-local .git/config; global and system git configuration is intentionally ignored
- StatusDate extraction uses HEAD reference resolution to find the commit date; falls back to .git folder modification time if HEAD is unavailable
- Breaking change consideration: New properties are additive and backwards-compatible; existing serialized repository lists will deserialize successfully with null values for new properties

## [1.0.0] - 2025-10-31
- New: Command Get-DevDirectory
    - Scans a directory tree and returns metadata about all Git repositories found
    - Performs breadth-first traversal that stops descending at repository roots
    - Resolves remote URLs for each repository without invoking external git commands
    - Returns strongly-typed DevDirManager.Repository objects with RelativePath, FullPath, RemoteName, and RemoteUrl properties
- New: Command Export-DevDirectoryList
    - Writes repository lists to disk in JSON or XML format
    - Accepts pipeline input and aggregates entries before serialization
    - Automatically infers format from file extension or accepts explicit Format parameter
- New: Command Import-DevDirectoryList
    - Imports repository lists from JSON or XML files
    - Automatically detects format from file extension
    - Returns strongly-typed DevDirManager.Repository objects for downstream processing
- New: Command Restore-DevDirectory
    - Clones repositories from a repository list while preserving folder layout
    - Supports Force switch to overwrite existing directories
    - Supports SkipExisting switch to skip repositories whose directories already exist
    - Returns DevDirManager.CloneResult objects with status information
    - Includes comprehensive path validation to prevent directory traversal attacks
- New: Command Sync-DevDirectoryList
    - Bi-directional synchronization between local directory and repository list file
    - Clones repositories that exist only in the file
    - Adds locally discovered repositories to the list
    - Intelligently merges metadata when conflicts are detected
    - Returns merged repository list when PassThru switch is specified
- New: Command Publish-DevDirectoryList
    - Publishes repository lists to GitHub Gists
    - Creates new gists or updates existing ones by description or ID
    - Supports both pipeline input and file-based input
    - Returns DevDirManager.GistResult objects with gist URL and metadata
- New: Custom type definitions
    - DevDirManager.Repository type for repository metadata objects
    - DevDirManager.CloneResult type for clone operation results
    - DevDirManager.GistResult type for gist publication results
    - Custom format views provide clean tabular output in the console
- New: Comprehensive inline documentation
    - All functions include detailed comment-based help with examples
    - Internal code includes extensive developer comments explaining algorithms and design decisions
    - Security considerations and edge cases are documented throughout