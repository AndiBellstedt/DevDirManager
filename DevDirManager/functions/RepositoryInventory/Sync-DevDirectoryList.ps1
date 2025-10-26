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
        The JSON file (compatible with Export-DevDirectoryList) used to store the shared repository list.

    .PARAMETER RemoteName
        The Git remote name to inspect when building the local repository list. Defaults to "origin".

    .PARAMETER GitExecutable
        The git executable to use when cloning repositories that exist only in the repository list file.
        Defaults to "git".

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
        Version   : 1.0.0
        Author    : Andi Bellstedt, Copilot
        Date      : 2025-10-26
        Keywords  : Git, Sync, Repository

    .LINK
        https://github.com/AndiBellstedt/DevDirManager

    #>
    [CmdletBinding(
        SupportsShouldProcess = $true,
        ConfirmImpact = "Medium"
    )]
    [OutputType([pscustomobject[]])]
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
        [ValidateNotNullOrEmpty()]
        [string]
        $RemoteName = "origin",

        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [string]
        $GitExecutable = "git",

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
        $normalizedDirectory = [System.IO.Path]::GetFullPath($DirectoryPath)
        if (-not $normalizedDirectory.EndsWith("\", [System.StringComparison]::Ordinal)) {
            $normalizedDirectory = "$($normalizedDirectory)\"
        }
        $trimmedDirectory = $normalizedDirectory.TrimEnd("\")

        $repositoryDirectory = Split-Path -Path $RepositoryListPath -Parent

        $invalidRelativePattern = [regex]::new("(^\\|:|\.\.)")
        $comparer = [System.StringComparer]::OrdinalIgnoreCase
        $localMap = [System.Collections.Generic.Dictionary[string, psobject]]::new($comparer)
        $finalMap = [System.Collections.Generic.Dictionary[string, psobject]]::new($comparer)
        $fileEntriesInfo = [System.Collections.Generic.Dictionary[string, psobject]]::new($comparer)
        $repositoriesToClone = [System.Collections.Generic.List[psobject]]::new()
        $changesMade = $false

        $normalizeRelativePath = {
            param(
                [Parameter(Mandatory = $true)]
                [string]
                $Path
            )

            if ([string]::IsNullOrWhiteSpace($Path) -or $Path -eq ".") {
                return "."
            }

            $cleaned = $Path.Trim()
            $cleaned = $cleaned -replace "\\\\", "/"
            $cleaned = $cleaned -replace "^/+", ""
            $cleaned = $cleaned -replace "/+$", ""
            if ([string]::IsNullOrWhiteSpace($cleaned)) {
                return "."
            }

            return ($cleaned -replace "/", "\\")
        }

        $newSyncRecord = {
            param(
                [Parameter(Mandatory = $true)]
                [string]
                $RelativePath,

                [Parameter()]
                [string]
                $RemoteUrl,

                [Parameter()]
                [string]
                $Remote
            )

            $effectiveRelativePath = if ([string]::IsNullOrEmpty($RelativePath)) { "." } else { $RelativePath }
            $remoteName = if ([string]::IsNullOrEmpty($Remote)) { $RemoteName } else { $Remote }
            $fullPath = if ($effectiveRelativePath -eq ".") { $trimmedDirectory } else { Join-Path -Path $trimmedDirectory -ChildPath $effectiveRelativePath }

            [pscustomobject]@{
                RootPath     = $trimmedDirectory
                RelativePath = $effectiveRelativePath
                FullPath     = $fullPath
                RemoteName   = $remoteName
                RemoteUrl    = $RemoteUrl
            }
        }
    }

    process {
        # No per-item processing required; synchronization occurs in the end block.
    }

    end {
        $repositoryFileExists = Test-Path -LiteralPath $RepositoryListPath -PathType Leaf
        $fileEntriesRaw = @()
        if ($repositoryFileExists) {
            try {
                $fileEntriesRaw = Import-DevDirectoryList -Path $RepositoryListPath -Format Json
            } catch {
                throw "Unable to import repository list from $($RepositoryListPath): $($_.Exception.Message)"
            }
        }

        foreach ($entry in $fileEntriesRaw) {
            $relative = & $normalizeRelativePath ([string]$entry.RelativePath)
            if ($invalidRelativePattern.IsMatch($relative)) {
                Write-PSFMessage -Level Warning -Message "Repository list entry with unsafe relative path $relative has been skipped."
                continue
            }

            $remoteUrl = [string]$entry.RemoteUrl
            $remoteName = if ($entry.PSObject.Properties.Match("RemoteName")) { [string]$entry.RemoteName } else { $RemoteName }
            $originalRoot = if ($entry.PSObject.Properties.Match("RootPath")) { [string]$entry.RootPath } else { $null }
            $originalFull = if ($entry.PSObject.Properties.Match("FullPath")) { [string]$entry.FullPath } else { $null }

            $info = [pscustomobject]@{
                RelativePath     = $relative
                RemoteUrl        = $remoteUrl
                RemoteName       = $remoteName
                OriginalRootPath = $originalRoot
                OriginalFullPath = $originalFull
            }

            $fileEntriesInfo[$relative] = $info
        }

        $directoryExists = Test-Path -LiteralPath $trimmedDirectory -PathType Container
        if (-not $directoryExists) {
            if ($PSCmdlet.ShouldProcess($trimmedDirectory, "Create repository root directory")) {
                New-Item -ItemType Directory -Path $trimmedDirectory -Force -ErrorAction Stop | Out-Null
                $directoryExists = $true
            }
        }

        $localEntriesRaw = if ($directoryExists) {
            Get-DevDirectory -RootPath $trimmedDirectory -RemoteName $RemoteName
        } else {
            @()
        }

        foreach ($entry in $localEntriesRaw) {
            $relative = & $normalizeRelativePath ([string]$entry.RelativePath)
            if ($invalidRelativePattern.IsMatch($relative)) {
                Write-PSFMessage -Level Verbose -Message "Ignoring local repository with unsafe relative path $relative."
                continue
            }

            $record = & $newSyncRecord -RelativePath $relative -RemoteUrl ([string]$entry.RemoteUrl) -Remote ([string]$entry.RemoteName)
            $localMap[$relative] = $record
            $finalMap[$relative] = $record

            if (-not $fileEntriesInfo.ContainsKey($relative)) {
                $changesMade = $true
            }
        }

        foreach ($info in $fileEntriesInfo.Values) {
            $relative = $info.RelativePath
            $remoteUrl = $info.RemoteUrl
            $remoteName = $info.RemoteName
            $expectedFullPath = if ($relative -eq ".") { $trimmedDirectory } else { Join-Path -Path $trimmedDirectory -ChildPath $relative }

            if ($localMap.ContainsKey($relative)) {
                $existing = $finalMap[$relative]

                if ([string]::IsNullOrWhiteSpace($existing.RemoteUrl) -and -not [string]::IsNullOrWhiteSpace($remoteUrl)) {
                    $existing.RemoteUrl = $remoteUrl
                    $changesMade = $true
                } elseif (-not [string]::IsNullOrWhiteSpace($remoteUrl) -and -not [string]::IsNullOrWhiteSpace($existing.RemoteUrl) -and ($existing.RemoteUrl -ne $remoteUrl)) {
                    Write-PSFMessage -Level Verbose -Message "Remote URL mismatch for $relative. Keeping local value $($existing.RemoteUrl) over file value $remoteUrl."
                }

                if (-not [string]::IsNullOrWhiteSpace($remoteName) -and $existing.RemoteName -ne $remoteName) {
                    if ([string]::IsNullOrWhiteSpace($existing.RemoteName)) {
                        $existing.RemoteName = $remoteName
                        $changesMade = $true
                    }
                }

                if ($info.OriginalRootPath -ne $trimmedDirectory -or $info.OriginalFullPath -ne $expectedFullPath) {
                    $changesMade = $true
                }
            } else {
                $record = & $newSyncRecord -RelativePath $relative -RemoteUrl $remoteUrl -Remote $remoteName
                $finalMap[$relative] = $record
                $changesMade = $true

                if ([string]::IsNullOrWhiteSpace($remoteUrl)) {
                    Write-PSFMessage -Level Warning -Message "Repository list entry $relative lacks a RemoteUrl and cannot be cloned."
                } else {
                    $repositoriesToClone.Add([pscustomobject]@{
                            RelativePath = $relative
                            RemoteUrl    = $remoteUrl
                        })
                }

                if ($info.OriginalRootPath -ne $trimmedDirectory -or $info.OriginalFullPath -ne $expectedFullPath) {
                    $changesMade = $true
                }
            }
        }

        if ($repositoriesToClone.Count -gt 0) {
            if (-not $directoryExists) {
                Write-PSFMessage -Level Warning -Message "Repository root directory $trimmedDirectory does not exist; skipping clone operations."
            } elseif ($PSCmdlet.ShouldProcess($trimmedDirectory, "Clone $($repositoriesToClone.Count) repository/repositories from list")) {
                $restoreParameters = @{
                    InputObject     = $repositoriesToClone.ToArray()
                    DestinationPath = $trimmedDirectory
                    GitExecutable   = $GitExecutable
                }

                if ($Force.IsPresent) { $restoreParameters.Force = $true }
                if ($SkipExisting.IsPresent) { $restoreParameters.SkipExisting = $true }

                Restore-DevDirectory @restoreParameters
            }
        }

        $finalEntries = $finalMap.Values | Sort-Object -Property RelativePath

        if (-not $repositoryFileExists -or $changesMade) {
            if (-not [string]::IsNullOrEmpty($repositoryDirectory) -and -not (Test-Path -LiteralPath $repositoryDirectory -PathType Container)) {
                if ($PSCmdlet.ShouldProcess($repositoryDirectory, "Create directory for repository list file")) {
                    New-Item -ItemType Directory -Path $repositoryDirectory -Force -ErrorAction Stop | Out-Null
                }
            }

            if ($PSCmdlet.ShouldProcess($RepositoryListPath, "Update repository list file")) {
                $finalEntries | Export-DevDirectoryList -Path $RepositoryListPath -Format Json
            }
        } elseif (-not $repositoryFileExists) {
            if ($PSCmdlet.ShouldProcess($RepositoryListPath, "Update repository list file")) {
                $finalEntries | Export-DevDirectoryList -Path $RepositoryListPath -Format Json
            }
        }

        if ($PassThru.IsPresent) {
            $finalEntries
        }
    }
}
