function Get-DevDirectory {
    <#
    .SYNOPSIS
        Scans a directory tree and returns metadata about all Git repositories found.

    .DESCRIPTION
        Performs a breadth-first traversal that stops descending once a Git repository root is discovered.
        For every repository, the function resolves the remote URL for the specified remote name and
        returns objects that capture the relative location, remote details, repository-local user
        configuration (user.name and user.email), and the most recent activity date. The relative path
        enables restoring the identical directory layout on another system.

    .PARAMETER RootPath
        The directory that serves as the traversal root. The default is the current location.

    .PARAMETER SkipRemoteCheck
        If specified, skips the remote accessibility check. By default, the function tests whether
        each repository's remote URL is accessible using `git ls-remote`. This check helps identify
        deleted, moved, or otherwise unavailable remote repositories. Skipping the check improves
        performance but won't mark inaccessible repositories.

    .EXAMPLE
        PS C:\> Get-DevDirectory -RootPath "C:\Projects"

        Lists all repositories under C:\Projects, checks remote accessibility, and includes the
        configured remote URL for each entry.

    .EXAMPLE
        PS C:\> Get-DevDirectory -RootPath "C:\Projects" -SkipRemoteCheck

        Lists all repositories under C:\Projects without checking if remotes are accessible.
        This is faster but won't mark inaccessible repositories.

    .NOTES
        Version   : 1.3.3
        Author    : Andi Bellstedt, Copilot
        Date      : 2025-11-09
        Keywords  : Git, Inventory, Repository

    .LINK
        https://github.com/AndiBellstedt/DevDirManager

    #>
    [CmdletBinding()]
    [OutputType('DevDirManager.Repository')]
    param(
        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [string]
        $RootPath = (Get-Location).ProviderPath,

        [Parameter()]
        [switch]
        $SkipRemoteCheck
    )

    begin {
        Write-PSFMessage -Level Debug -String 'GetDevDirectory.Start' -StringValues @($RootPath, $SkipRemoteCheck) -Tag "GetDevDirectory", "Start"

        # Retrieve the default remote name from configuration
        # This allows users to configure a custom remote name via Set-PSFConfig
        $remoteName = Get-PSFConfigValue -FullName 'DevDirManager.Git.RemoteName'
        Write-PSFMessage -Level System -String 'GetDevDirectory.ConfigurationRemoteName' -StringValues @($remoteName) -Tag "GetDevDirectory", "Configuration"

        # Initialize a strongly-typed list to collect repository metadata throughout the scan
        # Using List[T] provides better performance than += array concatenation for large result sets
        $repositoryLayoutList = [System.Collections.Generic.List[pscustomobject]]::new()
    }

    process {
        # Resolve the root path to its canonical absolute form with trailing backslash
        # This ensures consistent path comparison and relative path calculation
        $normalizedRoot = Resolve-NormalizedPath -Path $RootPath -EnsureTrailingBackslash
        Write-PSFMessage -Level Verbose -String 'GetDevDirectory.ScanStart' -StringValues @($normalizedRoot.TrimEnd('\\')) -Tag "GetDevDirectory", "Scan"

        # Use breadth-first search (BFS) with a queue instead of recursion to avoid stack overflow
        # when scanning deeply nested directory structures. BFS also allows us to stop descending
        # at repository boundaries, which is more efficient than depth-first approaches.
        $rootUri = [System.Uri]::new($normalizedRoot)
        $pendingDirectoryQueue = [System.Collections.Generic.Queue[string]]::new()
        # Enqueue the root directory without trailing backslash for directory enumeration
        $pendingDirectoryQueue.Enqueue($normalizedRoot.TrimEnd("\"))

        while ($pendingDirectoryQueue.Count -gt 0) {
            # Dequeue the next directory to process
            $currentDirectory = $pendingDirectoryQueue.Dequeue()
            $gitFolderPath = Join-Path -Path $currentDirectory -ChildPath ".git"

            # Check if this directory is a Git repository root (contains .git folder)
            if (Test-Path -LiteralPath $gitFolderPath -PathType Container) {
                Write-PSFMessage -Level Debug -String 'GetDevDirectory.RepositoryFound' -StringValues @($currentDirectory) -Tag "GetDevDirectory", "Repository"

                # Found a repository; extract remote URL using the internal helper function
                $remoteUrl = Get-DevDirectoryRemoteUrl -RepositoryPath $currentDirectory -RemoteName $remoteName

                # Extract repository-local user information (user.name and user.email)
                $userInfo = Get-DevDirectoryUserInfo -RepositoryPath $currentDirectory

                # Retrieve the most recent commit or modification date
                $statusDate = Get-DevDirectoryStatusDate -RepositoryPath $currentDirectory

                # Check if remote URL is accessible (unless skipped for performance)
                $isRemoteAccessible = $null
                if (-not $SkipRemoteCheck) {
                    # Only check if we have a valid remote URL
                    if (-not [string]::IsNullOrWhiteSpace($remoteUrl)) {
                        Write-PSFMessage -Level Debug -String 'GetDevDirectory.RemoteCheckStart' -StringValues @($remoteUrl) -Tag "GetDevDirectory", "RemoteCheck"
                        $isRemoteAccessible = Test-DevDirectoryRemoteAccessible -RemoteUrl $remoteUrl
                        Write-PSFMessage -Level Verbose -String 'GetDevDirectory.RemoteCheckResult' -StringValues @($relativePath, $isRemoteAccessible) -Tag "GetDevDirectory", "RemoteCheck"
                    } else {
                        # No remote URL means not accessible
                        $isRemoteAccessible = $false
                        Write-PSFMessage -Level Verbose -String 'GetDevDirectory.RemoteCheckNoUrl' -StringValues @($relativePath) -Tag "GetDevDirectory", "RemoteCheck"
                    }
                }

                # Calculate the relative path from the scan root to this repository
                # URI-based relative path calculation handles special characters and encodings correctly
                $resolvedCurrent = [System.IO.Path]::GetFullPath($currentDirectory)
                if (-not $resolvedCurrent.EndsWith("\", [System.StringComparison]::Ordinal)) {
                    $resolvedCurrent = "$($resolvedCurrent)\"
                }

                $currentUri = [System.Uri]::new($resolvedCurrent)
                $relativeUri = $rootUri.MakeRelativeUri($currentUri)
                $relativePath = [System.Uri]::UnescapeDataString($relativeUri.ToString()).TrimEnd("/")

                # Handle the edge case where the repository is at the root of the scan path
                if ([string]::IsNullOrEmpty($relativePath)) {
                    $relativePath = "."
                }

                # Convert forward slashes (from URI) to backslashes (Windows convention)
                $relativePath = $relativePath.Replace("/", "\")

                # Add the repository metadata record to the result collection
                # This structure is compatible with Export/Import and Restore/Sync commands
                $repositoryLayoutList.Add([pscustomobject]@{
                        PSTypeName         = 'DevDirManager.Repository'
                        RootPath           = $normalizedRoot.TrimEnd("\\")
                        RelativePath       = $relativePath
                        FullPath           = $resolvedCurrent.TrimEnd("\\")
                        RemoteName         = $remoteName
                        RemoteUrl          = $remoteUrl
                        UserName           = $userInfo.UserName
                        UserEmail          = $userInfo.UserEmail
                        StatusDate         = $statusDate
                        IsRemoteAccessible = $isRemoteAccessible
                    })

                # Do NOT descend into subdirectories of a repository (treat repo as a leaf node)
                # This prevents scanning nested repositories or internal .git structures
                continue
            }

            # This directory is not a repository root; enumerate its child directories
            $childDirectoryList = @()
            try {
                $childDirectoryList = Get-ChildItem -LiteralPath $currentDirectory -Directory -ErrorAction Stop
            } catch {
                # Directory enumeration can fail due to permissions or I/O errors
                # Log the issue and continue scanning other directories
                Write-PSFMessage -Level Verbose -String 'GetDevDirectory.DirectoryEnumerationFailed' -StringValues @($currentDirectory, $_.Exception.Message)
            }

            # Enqueue child directories for subsequent processing (breadth-first order)
            foreach ($childDirectory in $childDirectoryList) {
                # Skip .git folders to avoid processing Git internals as repositories
                if ($childDirectory.Name -eq ".git") {
                    continue
                }

                $pendingDirectoryQueue.Enqueue($childDirectory.FullName)
            }
        }
    }

    end {
        Write-PSFMessage -Level Verbose -String 'GetDevDirectory.ScanComplete' -StringValues @($repositoryLayoutList.Count) -Tag "GetDevDirectory", "Result"

        # Convert the List to an array for output to match the declared OutputType
        # This ensures compatibility with downstream commands expecting array input
        $repositoryLayoutList.ToArray()
    }
}
