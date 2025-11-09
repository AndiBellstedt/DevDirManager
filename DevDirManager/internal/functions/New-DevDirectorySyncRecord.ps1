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

    .EXAMPLE
        PS C:\> New-DevDirectorySyncRecord -RelativePath "MyProject" -RemoteUrl "https://github.com/user/repo.git" -RemoteName "origin" -RootDirectory "C:\Repos"

        Creates a repository sync record for MyProject with the specified remote URL.

    .NOTES
        Author    : Andi Bellstedt, Copilot
        Date      : 2025-10-31
        Version   : 1.1.0
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
        $StatusDate
    )

    # Normalize the relative path: empty strings are treated as "." (repository at root)
    $effectiveRelativePath = if ([string]::IsNullOrEmpty($RelativePath)) { "." } else { $RelativePath }

    # Compute the full absolute path by combining root and relative path
    # Special case: if the relative path is ".", the full path is simply the root directory
    $fullPath = if ($effectiveRelativePath -eq ".") {
        $RootDirectory
    } else {
        Join-Path -Path $RootDirectory -ChildPath $effectiveRelativePath
    }

    # Construct and return the standardized sync record object
    # All properties are consistently ordered and typed for downstream processing
    [pscustomobject]@{
        PSTypeName   = 'DevDirManager.Repository'
        RootPath     = $RootDirectory        # Base directory for all repositories
        RelativePath = $effectiveRelativePath # Normalized relative path (never empty)
        FullPath     = $fullPath             # Computed absolute path
        RemoteName   = $RemoteName           # Git remote name (e.g., "origin")
        RemoteUrl    = $RemoteUrl            # Git remote URL (may be null/empty)
        UserName     = $UserName             # Repository-local git user.name
        UserEmail    = $UserEmail            # Repository-local git user.email
        StatusDate   = $StatusDate           # Most recent commit or modification date
    }
}
