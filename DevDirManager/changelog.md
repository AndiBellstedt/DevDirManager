# Changelog

## [1.4.2] - 2025-12-27

### Overview
This release focuses on dashboard improvements and bug fixes. The graphical dashboard now features a redesigned interface with better control alignment across all tabs, and several WhatIf-related issues have been resolved. No breaking changes.

### Changed
- **Dashboard UI redesign for improved usability**
  - Reorganized all three tabs (Discover & Export, Import & Restore, Sync) with consistent professional layout
  - Aligned all text input fields at fixed 110px label column for visual consistency
  - Standardized action button sizes (Scan, Load, Export, Restore, Sync) with MinWidth 100px
  - Moved all controls above the data grid for logical top-to-bottom workflow
  - **Discover & Export tab**: Format dropdown, summary text, Scan and Export buttons now on same row
  - **Import & Restore tab**: Checkboxes, summary text, Load and Restore buttons now on same row
  - **Sync tab**: Swapped Data file and Workspace field order; moved summary text inline with action buttons
  - Removed separator lines in favor of cleaner spacing between control groups

### Fixed
- **Dashboard Sync WhatIf functionality**
  - Fixed runtime error when using WhatIf option in the Sync tab (formatting exception with mismatched argument count)
  - Suppressed unwanted WhatIf messages from internal operations (temp file cleanup, remote accessibility checks)
  - Fixed PowerShell 7 compatibility: prevented "What if: Start-Process" spam during remote checks
  - Fixed PowerShell 5.1 compatibility: suppressed WhatIf mode during Start-Process calls by temporarily setting preference variables
  - Dashboard status text now displays WhatIf summary (e.g., "Clone X repositories from list", "Update repository list file")
  - WhatIf summary is also shown in a message box for clear user feedback

- **Dashboard asset handling**
  - Removed external asset access that attempted to copy logo from outside the module folder
  - Dashboard now loads logo directly from within the module structure (read-only)

## [1.4.0] - 2025-11-12

Overview
- For users upgrading from 1.3.0, this release introduces a simple graphical dashboard and streamlines daily workflows. All existing PowerShell commands remain unchanged and fully supported. No breaking changes.

### Added
- **New graphical dashboard (Show-DevDirectoryDashboard)**
  - Manage Discover, Export, Import, Restore, and Sync in one window
  - Adapts to Windows light/dark mode automatically
  - Professional, consistent styling throughout
  - Choose a repository list file once; the path is reused across Import, Restore, and Sync
  - Clear visual feedback during longer operations (busy buttons and status bar messages)
  - Resizable/reorderable columns in the results grids for easier review and sorting

### Changed
- **User experience improvements**
  - add localization: German
  - refactor localization for: English, Spanish, French

### Compatibility and upgrade notes
- No changes to existing commands or parameters; scripts written for 1.3.0 continue to work
- The new dashboard is optional—launch it when you prefer a GUI: `Show-DevDirectoryDashboard`

## [1.3.0] - 2025-11-09

### Added
- **Comprehensive PSFramework Logging**
  - Added comprehensive `Write-PSFMessage` logging to all public and internal functions
  - Logging includes appropriate levels: Debug (detailed operations), Verbose (informational), System (technical details), Error/Warning (issues)
  - Messages include Tags for categorization and filtering (e.g., "GetDevDirectory", "Export", "Import", "Restore", "Sync", "Publish")
  - **Get-DevDirectory**:
    - Debug logging for function start with parameters and repository discovery
    - System logging for configuration usage
    - Verbose logging for scanning operations and remote accessibility checks
    - Significant logging for completion with repository count
  - **Export-DevDirectoryList**:
    - Debug logging for function start and object collection
    - System logging for format detection and configuration
    - Verbose logging for export processing and serialization steps
    - Significant logging for completion with export count
  - **Import-DevDirectoryList**:
    - Debug logging for function start and deserialization methods
    - System logging for format configuration
    - Warning logging for file not found
    - Verbose logging for import operations and type conversions
    - Significant logging for completion with import count
  - **Restore-DevDirectory**:
    - Enhanced existing logging with Debug logging for function start and configuration
    - System logging for git executable resolution
    - Verbose logging for destination path normalization
    - Significant logging for operation completion
    - Already had comprehensive logging for clone operations, errors, and warnings
  - **Sync-DevDirectoryList**:
    - Debug logging for function start with all parameters
    - System logging for configuration usage
    - Verbose logging for synchronization process stages
    - Significant logging for completion with repository count
  - **Publish-DevDirectoryList**:
    - Debug logging for function start and collection
    - System logging for authentication and API configuration
    - Verbose logging for file reading, format detection, gist queries, and operations
    - Significant logging for successful publish with gist details
    - System logging for cleanup operations
  - **Resolve-RepositoryListFormat**:
    - Debug logging for function entry, extension extraction, and format inference
    - Verbose logging for fallback to default format and final resolved format
    - Warning logging for format inference failure
  - **Resolve-NormalizedPath**:
    - Debug logging for function entry, path resolution, normalization, and formatting
    - Verbose logging for completion with normalized path result
    - Error logging for invalid path parameter
  - **New-DirectoryIfNeeded**:
    - Debug logging for each directory being processed
    - Verbose logging for skipped (already existing) directories and successful creation
  - **New-DevDirectorySyncRecord**:
    - Debug logging for function entry, relative path normalization, and full path computation
    - Verbose logging for sync record creation with path details
  - **Get-DevDirectoryUserInfo**:
    - Debug logging for function entry, config path resolution, file reading, and parsing
    - Verbose logging for user info extraction result and missing config scenarios
  - **Get-DevDirectoryStatusDate**:
    - Debug logging for function entry, git folder path, HEAD reference check, and fallback
    - Verbose logging for status date extraction from branch ref, detached HEAD, or .git directory
  - **Get-DevDirectoryRemoteUrl**:
    - Debug logging for function entry, config path resolution, file reading, and section pattern search
    - Verbose logging for remote URL result and missing remote/config scenarios
  - **ConvertTo-NormalizedRelativePath**:
    - Debug logging for function entry and normalization steps
    - Verbose logging for empty/root path handling and final normalized result
  - **Add-RepositoryTypeName**:
    - Debug logging for adding type name to objects
    - Verbose logging for type name addition completion

### Changed
- **Improved Logging for Existing Target Directories**
  - Changed "target directory already exists" message level from Warning to VeryVerbose in `Restore-DevDirectory`
  - This is expected behavior when directories exist without `-Force` or `-SkipExisting`, not an actionable warning
  - Reduces noise in standard output while information remains available with `-Verbose`

### Added (Previous Features)
- **Improved Git Clone with Progress Tracking and Output Control**
  - `Restore-DevDirectory` now suppresses git command output by default (follows PowerShell best practice: no console output unless something goes wrong)
  - Added `-ShowGitOutput` parameter to `Restore-DevDirectory` to explicitly display git clone output for troubleshooting
  - Implemented progress bar with `Write-Progress` showing current operation, repository count, and percentage complete
  - Progress tracking provides better user experience during long clone operations
  - `Sync-DevDirectoryList` forwards `-ShowGitOutput` parameter to `Restore-DevDirectory`
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

### Fixed
- Fixed missing localization string `RestoreDevDirectory.ConfigFailed` for git config error messages
- Fixed CSV StatusDate type conversion issue
  - Import-DevDirectoryList now correctly parses StatusDate from CSV using try-catch with Parse() method
  - Resolves issue where CSV imports would leave StatusDate as string instead of DateTime on systems with non-US cultures
  - Fixed Windows PowerShell 5.1 compatibility issue with TryParse() method overloads
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
- Fixed Windows PowerShell 5.1 compatibility in RemoteAccessibility tests
  - Fixed DateTime serialization issue in test data for Sync-DevDirectoryList tests
  - StatusDate property now explicitly cast to [DateTime] to prevent serialization issues in Windows PowerShell
  - Resolves "Cannot convert value to type System.DateTime" errors when importing test repository data
- Fixed double backslash issue in RelativePath property
  - Get-DevDirectory now uses `.Replace()` instead of `-replace` for path separator conversion
  - RelativePath now correctly uses single backslashes (e.g., `Project\Repo` instead of `Project\\Repo`)
  - Ensures paths can be properly split and reconstructed using standard PowerShell path operations
  - Fixes display and export issues where double backslashes appeared in relative paths

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

### Changed - Code Refactoring (Part 1)
- Refactored common code patterns into reusable internal components for better maintainability
  - Created `Resolve-NormalizedPath` internal function to handle path resolution and normalization (eliminates duplicate code across Get-DevDirectory, Restore-DevDirectory)
  - Improved code reusability and test coverage across the module

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