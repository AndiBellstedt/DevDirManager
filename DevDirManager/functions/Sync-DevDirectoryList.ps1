function Sync-DevDirectoryList {
    <#
    .SYNOPSIS
        Synchronizes a directory of Git repositories with a repository list JSON file.

    .DESCRIPTION
        Compares the repositories present beneath the specified directory with those described in the
        repository list file. Repositories that exist only in the file are cloned locally, while
        repositories that exist only on disk are added to the repository list. The resulting combined
        list is written back to the JSON file, enabling multiple computers to share the same repository
        inventory.

    .PARAMETER DirectoryPath
        The root directory that contains the Git repositories to synchronize. When the directory does not
        exist it will be created.

    .PARAMETER RepositoryListPath
        The repository list file (compatible with Export-DevDirectoryList) used to store the shared repository list.
        Supports CSV, JSON, and XML formats. Format is auto-detected from the file extension.

    .PARAMETER Force
        Forwards to Restore-DevDirectory to overwrite existing directories when cloning.

    .PARAMETER SkipExisting
        Forwards to Restore-DevDirectory to skip cloning repositories whose directories already exist.

    .PARAMETER PassThru
        Returns the merged repository list after synchronization.

    .PARAMETER WhatIf
        Shows what would happen if the command runs. The command supports -WhatIf because it
        performs potentially destructive operations such as creating directories or writing files.

    .PARAMETER Confirm
        Prompts for confirmation before executing operations that change the system. The command
        supports -Confirm because it uses ShouldProcess for create/update actions.

    .EXAMPLE
        PS C:\> Sync-DevDirectoryList -DirectoryPath "C:\Repos" -RepositoryListPath "C:\Repos\repos.json"

        Synchronizes the repositories beneath C:\Repos with the entries stored in repos.json, cloning any
        repositories that exist only in the file and adding locally discovered repositories to the file.

    .NOTES
        Version   : 1.1.1
        Author    : Andi Bellstedt, Copilot
        Date      : 2025-10-31
        Keywords  : Git, Sync, Repository

    .LINK
        https://github.com/AndiBellstedt/DevDirManager

    #>
    [CmdletBinding(
        SupportsShouldProcess = $true,
        ConfirmImpact = "Medium"
    )]
    [OutputType('DevDirManager.Repository')]
    param(
        [Parameter(ValueFromPipelineByPropertyName = $true)]
        [ValidateNotNullOrEmpty()]
        [string]
        $DirectoryPath = (Get-Location).ProviderPath,

        [Parameter(ValueFromPipelineByPropertyName = $true, Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]
        $RepositoryListPath,

        [Parameter()]
        [switch]
        $Force,

        [Parameter()]
        [switch]
        $SkipExisting,

        [Parameter()]
        [switch]
        $PassThru
    )

    begin {
        # Retrieve configuration value for Git remote name
        # This allows users to customize this setting via Set-PSFConfig
        $remoteName = Get-PSFConfigValue -FullName 'DevDirManager.Git.RemoteName'

        # Normalize the target directory path to a canonical absolute form with trailing backslash
        # This ensures consistent path operations and comparisons throughout the sync logic
        $normalizedDirectory = [System.IO.Path]::GetFullPath($DirectoryPath)
        if (-not $normalizedDirectory.EndsWith("\", [System.StringComparison]::Ordinal)) {
            $normalizedDirectory = "$($normalizedDirectory)\"
        }
        # Store a trimmed version (no trailing slash) for cleaner output properties
        $trimmedDirectory = $normalizedDirectory.TrimEnd("\")

        # Extract the parent directory of the repository list file for later directory creation
        $repositoryDirectory = Split-Path -Path $RepositoryListPath -Parent

        # Regex pattern to detect unsafe relative paths:
        # - Starts with backslash (absolute path)
        # - Contains colon (drive letter)
        # - Contains ".." (path traversal)
        # These patterns could allow escaping the root directory or cause security issues
        $invalidRelativePattern = [regex]::new("(^\\|:|\.\.)")

        # Use case-insensitive string comparison for all path-based dictionary keys
        # This matches Windows file system behavior and prevents duplicate entries
        $comparer = [System.StringComparer]::OrdinalIgnoreCase

        # Dictionaries to track repositories discovered locally and from the file
        # Using Dictionary[string, psobject] provides O(1) lookups for merging logic
        $localMap = [System.Collections.Generic.Dictionary[string, psobject]]::new($comparer)
        $finalMap = [System.Collections.Generic.Dictionary[string, psobject]]::new($comparer)
        $fileEntriesInfo = [System.Collections.Generic.Dictionary[string, psobject]]::new($comparer)

        # List of repositories that exist in the file but not locally (need to be cloned)
        $repositoriesToClone = [System.Collections.Generic.List[psobject]]::new()

        # Track whether any modifications were made during sync (determines if file needs updating)
        $changesMade = $false

        $createRootDirectoryAction = Get-PSFLocalizedString -Module 'DevDirManager' -Name 'SyncDevDirectoryList.ActionCreateRootDirectory'
        $cloneFromListActionTemplate = Get-PSFLocalizedString -Module 'DevDirManager' -Name 'SyncDevDirectoryList.ActionCloneFromList'
        $createListDirectoryAction = Get-PSFLocalizedString -Module 'DevDirManager' -Name 'SyncDevDirectoryList.ActionCreateListDirectory'
        $updateListFileAction = Get-PSFLocalizedString -Module 'DevDirManager' -Name 'SyncDevDirectoryList.ActionUpdateListFile'
    }

    process {
        # No per-item processing required; synchronization occurs in the end block.
    }

    end {
        # Step 1: Load and normalize the repository list from the file (if it exists)
        # The format is auto-detected based on file extension or uses the configured default
        $repositoryFileExists = Test-Path -LiteralPath $RepositoryListPath -PathType Leaf
        $fileEntriesRaw = @()
        if ($repositoryFileExists) {
            try {
                $fileEntriesRaw = Import-DevDirectoryList -Path $RepositoryListPath
            } catch {
                $messageValues = @($RepositoryListPath, $_.Exception.Message)
                $messageTemplate = Get-PSFLocalizedString -Module 'DevDirManager' -Name 'SyncDevDirectoryList.ImportFailed'
                $message = $messageTemplate -f $messageValues
                Stop-PSFFunction -String 'SyncDevDirectoryList.ImportFailed' -StringValues $messageValues -EnableException $true -Cmdlet $PSCmdlet -ErrorRecord $_
                throw $message
            }
        }

        # Process each entry from the file and build a normalized lookup dictionary
        foreach ($entry in $fileEntriesRaw) {
            # Normalize the relative path using the internal helper function
            $relative = ConvertTo-NormalizedRelativePath -Path ([string]$entry.RelativePath)

            # Skip entries with unsafe paths (absolute, drive letters, or path traversal)
            if ($invalidRelativePattern.IsMatch($relative)) {
                Write-PSFMessage -Level Warning -String 'SyncDevDirectoryList.UnsafeFileEntry' -StringValues @($relative)
                continue
            }

            # Extract metadata from the file entry, providing defaults for missing properties
            $remoteUrl = [string]$entry.RemoteUrl
            $remoteName = if ($entry.PSObject.Properties.Match("RemoteName")) { [string]$entry.RemoteName } else { $RemoteName }
            $originalRoot = if ($entry.PSObject.Properties.Match("RootPath")) { [string]$entry.RootPath } else { $null }
            $originalFull = if ($entry.PSObject.Properties.Match("FullPath")) { [string]$entry.FullPath } else { $null }

            # Store a lightweight info object for later comparison with local repositories
            $info = [pscustomobject]@{
                RelativePath     = $relative
                RemoteUrl        = $remoteUrl
                RemoteName       = $remoteName
                OriginalRootPath = $originalRoot
                OriginalFullPath = $originalFull
            }

            $fileEntriesInfo[$relative] = $info
        }

        # Step 2: Scan the local directory for Git repositories
        $directoryExists = Test-Path -LiteralPath $trimmedDirectory -PathType Container
        if (-not $directoryExists) {
            # If the directory doesn't exist and user approves, create it
            if ($PSCmdlet.ShouldProcess($trimmedDirectory, $createRootDirectoryAction)) {
                New-Item -ItemType Directory -Path $trimmedDirectory -Force -ErrorAction Stop | Out-Null
                $directoryExists = $true
            }
        }

        # Scan for local repositories only if the directory exists
        $localEntriesRaw = if ($directoryExists) {
            Get-DevDirectory -RootPath $trimmedDirectory
        } else {
            @()
        }

        # Build the local repository map and add entries to the final merged map
        foreach ($entry in $localEntriesRaw) {
            $relative = ConvertTo-NormalizedRelativePath -Path ([string]$entry.RelativePath)

            # Skip local repositories with unsafe relative paths
            if ($invalidRelativePattern.IsMatch($relative)) {
                Write-PSFMessage -Level Verbose -String 'SyncDevDirectoryList.UnsafeLocalEntry' -StringValues @($relative)
                continue
            }

            # Create a sync record using the internal helper function
            $record = New-DevDirectorySyncRecord -RelativePath $relative -RemoteUrl ([string]$entry.RemoteUrl) -RemoteName ([string]$entry.RemoteName) -RootDirectory $trimmedDirectory

            # Add to both the local map (for later comparison) and the final map
            $localMap[$relative] = $record
            $finalMap[$relative] = $record

            # If this repository is not in the file, mark that changes were made
            if (-not $fileEntriesInfo.ContainsKey($relative)) {
                $changesMade = $true
            }
        }

        # Step 3: Merge file entries with local entries
        foreach ($info in $fileEntriesInfo.Values) {
            $relative = $info.RelativePath
            $remoteUrl = $info.RemoteUrl
            $remoteName = $info.RemoteName
            $expectedFullPath = if ($relative -eq ".") { $trimmedDirectory } else { Join-Path -Path $trimmedDirectory -ChildPath $relative }

            if ($localMap.ContainsKey($relative)) {
                # Repository exists both locally and in the file; merge metadata
                $existing = $finalMap[$relative]

                # If local entry is missing a remote URL but file has one, use the file's URL
                if ([string]::IsNullOrWhiteSpace($existing.RemoteUrl) -and -not [string]::IsNullOrWhiteSpace($remoteUrl)) {
                    $existing.RemoteUrl = $remoteUrl
                    $changesMade = $true
                } elseif (-not [string]::IsNullOrWhiteSpace($remoteUrl) -and -not [string]::IsNullOrWhiteSpace($existing.RemoteUrl) -and ($existing.RemoteUrl -ne $remoteUrl)) {
                    # Remote URL conflict: prefer the local value (it's more authoritative)
                    Write-PSFMessage -Level Verbose -String 'SyncDevDirectoryList.RemoteUrlMismatch' -StringValues @($relative, $existing.RemoteUrl, $remoteUrl)
                }

                # If local entry is missing a remote name but file has one, use the file's remote name
                if (-not [string]::IsNullOrWhiteSpace($remoteName) -and $existing.RemoteName -ne $remoteName) {
                    if ([string]::IsNullOrWhiteSpace($existing.RemoteName)) {
                        $existing.RemoteName = $remoteName
                        $changesMade = $true
                    }
                }

                # Detect if root/full paths changed (e.g., the repository was moved)
                if ($info.OriginalRootPath -ne $trimmedDirectory -or $info.OriginalFullPath -ne $expectedFullPath) {
                    $changesMade = $true
                }
            } else {
                # Repository exists only in the file (not locally); add to final map and clone list
                $record = New-DevDirectorySyncRecord -RelativePath $relative -RemoteUrl $remoteUrl -RemoteName $remoteName -RootDirectory $trimmedDirectory
                $finalMap[$relative] = $record
                $changesMade = $true

                # Queue for cloning if it has a valid remote URL
                if ([string]::IsNullOrWhiteSpace($remoteUrl)) {
                    Write-PSFMessage -Level Warning -String 'SyncDevDirectoryList.MissingRemoteUrl' -StringValues @($relative)
                } else {
                    $repositoriesToClone.Add([pscustomobject]@{
                            RelativePath = $relative
                            RemoteUrl    = $remoteUrl
                        })
                }

                # Detect path changes (file was created on a different machine with different root)
                if ($info.OriginalRootPath -ne $trimmedDirectory -or $info.OriginalFullPath -ne $expectedFullPath) {
                    $changesMade = $true
                }
            }
        }

        # Step 4: Clone repositories that exist only in the file
        if ($repositoriesToClone.Count -gt 0) {
            if (-not $directoryExists) {
                Write-PSFMessage -Level Warning -String 'SyncDevDirectoryList.MissingRootDirectory' -StringValues @($trimmedDirectory)
            } elseif ($PSCmdlet.ShouldProcess($trimmedDirectory, ($cloneFromListActionTemplate -f @($repositoriesToClone.Count)))) {
                # Build parameters for Restore-DevDirectory and forward switches
                $restoreParameters = @{
                    InputObject     = $repositoriesToClone.ToArray()
                    DestinationPath = $trimmedDirectory
                }

                if ($Force.IsPresent) { $restoreParameters.Force = $true }
                if ($SkipExisting.IsPresent) { $restoreParameters.SkipExisting = $true }

                # Invoke the restore command to clone missing repositories
                Restore-DevDirectory @restoreParameters
            }
        }

        # Step 5: Sort the final merged list by relative path for consistent output
        $finalEntries = $finalMap.Values | Sort-Object -Property RelativePath

        # Step 6: Update the repository list file if changes were detected or file doesn't exist
        if (-not $repositoryFileExists -or $changesMade) {
            # Ensure the directory for the repository list file exists
            if (-not [string]::IsNullOrEmpty($repositoryDirectory) -and -not (Test-Path -LiteralPath $repositoryDirectory -PathType Container)) {
                if ($PSCmdlet.ShouldProcess($repositoryDirectory, $createListDirectoryAction)) {
                    New-Item -ItemType Directory -Path $repositoryDirectory -Force -ErrorAction Stop | Out-Null
                }
            }

            # Write the updated repository list back to disk
            # Format is auto-detected from file extension or uses the configured default
            if ($PSCmdlet.ShouldProcess($RepositoryListPath, $updateListFileAction)) {
                $finalEntries | Export-DevDirectoryList -Path $RepositoryListPath
            }
        } elseif (-not $repositoryFileExists) {
            # Edge case: file doesn't exist and no changes were detected; still create it
            # Format is auto-detected from file extension or uses the configured default
            if ($PSCmdlet.ShouldProcess($RepositoryListPath, $updateListFileAction)) {
                $finalEntries | Export-DevDirectoryList -Path $RepositoryListPath
            }
        }

        # Step 7: Return the merged repository list if PassThru was specified
        if ($PassThru.IsPresent) {
            $finalEntries
        }
    }
}
