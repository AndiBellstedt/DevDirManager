function Get-DevDirectory {
    <#
    .SYNOPSIS
        Scans a directory tree and returns metadata about all Git repositories found.

    .DESCRIPTION
        Performs a breadth-first traversal that stops descending once a Git repository root is discovered.
        For every repository, the function resolves the remote URL for the specified remote name and
        returns objects that capture the relative location and remote details. The relative path enables
        restoring the identical directory layout on another system.

    .PARAMETER RootPath
        The directory that serves as the traversal root. The default is the current location.

    .EXAMPLE
        PS C:\> Get-DevDirectory -RootPath "C:\Projects"

        Lists all repositories under C:\Projects and includes the configured remote URL for each entry.

    .NOTES
        Version   : 1.1.0
        Author    : Andi Bellstedt, Copilot
        Date      : 2025-10-27
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
        $RootPath = (Get-Location).ProviderPath
    )

    begin {
        # Retrieve the default remote name from configuration
        # This allows users to configure a custom remote name via Set-PSFConfig
        $remoteName = Get-PSFConfigValue -FullName 'DevDirManager.Git.RemoteName'

        # Initialize a strongly-typed list to collect repository metadata throughout the scan
        # Using List[T] provides better performance than += array concatenation for large result sets
        $repositoryLayoutList = [System.Collections.Generic.List[pscustomobject]]::new()
    }

    process {
        # Resolve the root path to its canonical absolute form
        # This ensures consistent path comparison and relative path calculation
        $resolvedRoot = Resolve-Path -LiteralPath $RootPath -ErrorAction Stop
        $rootDirectory = $resolvedRoot.ProviderPath
        $normalizedRoot = [System.IO.Path]::GetFullPath($rootDirectory)

        # Ensure the normalized root ends with a backslash for consistent URI-based path operations
        if (-not $normalizedRoot.EndsWith("\", [System.StringComparison]::Ordinal)) {
            $normalizedRoot = "$($normalizedRoot)\"
        }

        # Use breadth-first search (BFS) with a queue instead of recursion to avoid stack overflow
        # when scanning deeply nested directory structures. BFS also allows us to stop descending
        # at repository boundaries, which is more efficient than depth-first approaches.
        $rootUri = [System.Uri]::new($normalizedRoot)
        $pendingDirectoryQueue = [System.Collections.Generic.Queue[string]]::new()
        $pendingDirectoryQueue.Enqueue($rootDirectory)

        while ($pendingDirectoryQueue.Count -gt 0) {
            # Dequeue the next directory to process
            $currentDirectory = $pendingDirectoryQueue.Dequeue()
            $gitFolderPath = Join-Path -Path $currentDirectory -ChildPath ".git"

            # Check if this directory is a Git repository root (contains .git folder)
            if (Test-Path -LiteralPath $gitFolderPath -PathType Container) {
                # Found a repository; extract remote URL using the internal helper function
                $remoteUrl = Get-DevDirectoryRemoteUrl -RepositoryPath $currentDirectory -RemoteName $remoteName

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
                $relativePath = $relativePath -replace "/", "\\"

                # Add the repository metadata record to the result collection
                # This structure is compatible with Export/Import and Restore/Sync commands
                $repositoryLayoutList.Add([pscustomobject]@{
                        PSTypeName   = 'DevDirManager.Repository'
                        RootPath     = $normalizedRoot.TrimEnd("\\")
                        RelativePath = $relativePath
                        FullPath     = $resolvedCurrent.TrimEnd("\\")
                        RemoteName   = $remoteName
                        RemoteUrl    = $remoteUrl
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
                Write-PSFMessage -Level Verbose -Message "Skipping directory $($currentDirectory) due to $($_.Exception.Message)."
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
        # Convert the List to an array for output to match the declared OutputType
        # This ensures compatibility with downstream commands expecting array input
        $repositoryLayoutList.ToArray()
    }
}
