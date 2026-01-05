function New-DevDirectorySyncRecord {
    <#
    .SYNOPSIS
        Internal helper that creates a standardized repository sync metadata record.

    .DESCRIPTION
        Constructs a PSCustomObject with consistent properties describing a repository's location
        and remote configuration. This helper is used by Sync-DevDirectoryList to build both the
        local and file-based repository inventories before merging them. Centralizing the object
        creation ensures all records have identical property sets and eliminates duplication.

    .PARAMETER RelativePath
        The repository's path relative to the root directory (e.g., "ProjectA" or "Subdir\ProjectB").

    .PARAMETER RemoteUrl
        The Git remote URL (e.g., "https://github.com/user/repo.git"). May be null if unknown.

    .PARAMETER RemoteName
        The name of the Git remote (e.g., "origin"). Defaults to the parent function's $RemoteName.

    .PARAMETER RootDirectory
        The absolute root directory path. Used to compute the full path for each repository.

    .PARAMETER UserName
        The repository-local git user.name value. May be null if not configured.

    .PARAMETER UserEmail
        The repository-local git user.email value. May be null if not configured.

    .PARAMETER StatusDate
        The most recent commit or modification date. May be null if not available.

    .PARAMETER SystemFilter
        The per-repository computer name filter pattern (e.g., "DEV-*", "!SERVER-*").
        Used to determine which computers should restore or sync this repository.
        May be null or empty to indicate no filtering (sync to all systems).

    .OUTPUTS
        [pscustomobject] A repository sync record with properties:
            - RootPath: the base directory path
            - RelativePath: the repository's relative location
            - FullPath: the absolute path to the repository
            - RemoteName: the Git remote name
            - RemoteUrl: the Git remote URL
            - UserName: the repository-local git user.name
            - UserEmail: the repository-local git user.email
            - StatusDate: the most recent activity date
            - SystemFilter: the computer name filter pattern

    .EXAMPLE
        PS C:\> New-DevDirectorySyncRecord -RelativePath "MyProject" -RemoteUrl "https://github.com/user/repo.git" -RemoteName "origin" -RootDirectory "C:\Repos"

        Creates a repository sync record for MyProject with the specified remote URL.

    .NOTES
        Author    : Andi Bellstedt, Copilot
        Date      : 2026-01-05
        Version   : 1.1.2
        Keywords  : Internal, Helper, Sync

    #>
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseShouldProcessForStateChangingFunctions', '', Justification = 'This function creates data objects and does not change system state')]
    [CmdletBinding()]
    [OutputType([pscustomobject])]
    param(
        [Parameter(Mandatory = $true)]
        [AllowEmptyString()]
        [string]
        $RelativePath,

        [Parameter()]
        [AllowEmptyString()]
        [string]
        $RemoteUrl,

        [Parameter()]
        [AllowEmptyString()]
        [string]
        $RemoteName,

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]
        $RootDirectory,

        [Parameter()]
        [AllowNull()]
        [string]
        $UserName,

        [Parameter()]
        [AllowNull()]
        [string]
        $UserEmail,

        [Parameter()]
        [AllowNull()]
        [datetime]
        $StatusDate,

        [Parameter()]
        [AllowNull()]
        [AllowEmptyString()]
        [string]
        $SystemFilter
    )

    Write-PSFMessage -Level Debug -Message "Creating sync record for RelativePath: '$($RelativePath)', RootDirectory: '$($RootDirectory)'" -Tag "NewDevDirectorySyncRecord", "Start"

    # Normalize the relative path: empty strings are treated as "." (repository at root)
    $effectiveRelativePath = if ([string]::IsNullOrEmpty($RelativePath)) { "." } else { $RelativePath }
    Write-PSFMessage -Level Debug -Message "Effective RelativePath: '$($effectiveRelativePath)'" -Tag "NewDevDirectorySyncRecord", "Normalization"

    # Compute the full absolute path by combining root and relative path
    # Special case: if the relative path is ".", the full path is simply the root directory
    $fullPath = if ($effectiveRelativePath -eq ".") {
        $RootDirectory
    } else {
        Join-Path -Path $RootDirectory -ChildPath $effectiveRelativePath
    }
    Write-PSFMessage -Level Debug -Message "Computed FullPath: '$($fullPath)'" -Tag "NewDevDirectorySyncRecord", "PathResolution"

    # Construct and return the standardized sync record object
    # All properties are consistently ordered and typed for downstream processing
    $syncRecord = [pscustomobject]@{
        PSTypeName   = 'DevDirManager.Repository'
        RootPath     = $RootDirectory        # Base directory for all repositories
        RelativePath = $effectiveRelativePath # Normalized relative path (never empty)
        FullPath     = $fullPath             # Computed absolute path
        RemoteName   = $RemoteName           # Git remote name (e.g., "origin")
        RemoteUrl    = $RemoteUrl            # Git remote URL (may be null/empty)
        UserName     = $UserName             # Repository-local git user.name
        UserEmail    = $UserEmail            # Repository-local git user.email
        StatusDate   = $StatusDate           # Most recent commit or modification date
        SystemFilter = $SystemFilter         # Per-repo computer name filter pattern
    }

    Write-PSFMessage -Level Verbose -Message "Sync record created for '$($effectiveRelativePath)' (FullPath: '$($fullPath)')" -Tag "NewDevDirectorySyncRecord", "Result"
    $syncRecord
}
