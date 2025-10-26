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

    .PARAMETER RemoteName
        The Git remote name whose URL should be reported. Defaults to "origin".

    .EXAMPLE
        PS C:\> Get-DevDirectory -RootPath "C:\Projects"

        Lists all repositories under C:\Projects and includes the origin remote URL for each entry.

    .NOTES
        Version   : 1.0.0
        Author    : Andi Bellstedt, Copilot
        Date      : 2025-10-26
        Keywords  : Git, Inventory, Repository

    .LINK
        https://github.com/AndiBellstedt/DevDirManager

    #>
    [CmdletBinding()]
    [OutputType([psobject[]])]
    param(
        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [string]
        $RootPath = (Get-Location).ProviderPath,

        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [string]
        $RemoteName = "origin"
    )

    begin {
        $repositoryLayoutList = [System.Collections.Generic.List[pscustomobject]]::new()

        function Get-DevDirectoryRemoteUrl {
            param(
                [Parameter(Mandatory = $true)]
                [ValidateNotNullOrEmpty()]
                [string]
                $RepositoryPath,

                [Parameter(Mandatory = $true)]
                [ValidateNotNullOrEmpty()]
                [string]
                $RemoteName
            )

            $gitFolderPath = Join-Path -Path $RepositoryPath -ChildPath ".git"
            $gitConfigPath = Join-Path -Path $gitFolderPath -ChildPath "config"

            if (-not (Test-Path -LiteralPath $gitConfigPath -PathType Leaf)) {
                # Use PSFramework logging to provide consistent output handling across the module
                Write-PSFMessage -Level Verbose -Message "No .git\\config file found at $($gitConfigPath)."
                return $null
            }

            $configLineList = Get-Content -LiteralPath $gitConfigPath -ErrorAction Stop
            $escapedRemoteName = [Regex]::Escape($RemoteName)
            $sectionPattern = "^\s*\[remote\s+`"$($escapedRemoteName)`"\]\s*$"
            $insideTargetSection = $false

            foreach ($line in $configLineList) {
                if ($line -match "^\s*\[.+\]\s*$") {
                    $insideTargetSection = ($line -match $sectionPattern)
                    continue
                }

                if ($insideTargetSection -and $line -match "^\s*url\s*=\s*(.+)$") {
                    return $matches[1].Trim()
                }
            }

            return $null
        }
    }

    process {
        $resolvedRoot = Resolve-Path -LiteralPath $RootPath -ErrorAction Stop
        $rootDirectory = $resolvedRoot.ProviderPath
        $normalizedRoot = [System.IO.Path]::GetFullPath($rootDirectory)

        if (-not $normalizedRoot.EndsWith("\", [System.StringComparison]::Ordinal)) {
            $normalizedRoot = "$($normalizedRoot)\"
        }

        # Prepare the traversal queue so we scan directories breadth-first and avoid stack overflows.
        $rootUri = [System.Uri]::new($normalizedRoot)
        $pendingDirectoryQueue = [System.Collections.Generic.Queue[string]]::new()
        $pendingDirectoryQueue.Enqueue($rootDirectory)

        while ($pendingDirectoryQueue.Count -gt 0) {
            $currentDirectory = $pendingDirectoryQueue.Dequeue()
            $gitFolderPath = Join-Path -Path $currentDirectory -ChildPath ".git"

            if (Test-Path -LiteralPath $gitFolderPath -PathType Container) {
                $remoteUrl = Get-DevDirectoryRemoteUrl -RepositoryPath $currentDirectory -RemoteName $RemoteName

                $resolvedCurrent = [System.IO.Path]::GetFullPath($currentDirectory)
                if (-not $resolvedCurrent.EndsWith("\", [System.StringComparison]::Ordinal)) {
                    $resolvedCurrent = "$($resolvedCurrent)\"
                }

                $currentUri = [System.Uri]::new($resolvedCurrent)
                $relativeUri = $rootUri.MakeRelativeUri($currentUri)
                $relativePath = [System.Uri]::UnescapeDataString($relativeUri.ToString()).TrimEnd("/")
                if ([string]::IsNullOrEmpty($relativePath)) {
                    $relativePath = "."
                }

                $relativePath = $relativePath -replace "/", "\\"

                # Capture repository metadata so downstream commands can recreate the layout.
                $repositoryLayoutList.Add([pscustomobject]@{
                        RootPath     = $normalizedRoot.TrimEnd("\\")
                        RelativePath = $relativePath
                        FullPath     = $resolvedCurrent.TrimEnd("\\")
                        RemoteName   = $RemoteName
                        RemoteUrl    = $remoteUrl
                    })

                continue
            }

            $childDirectoryList = @()
            try {
                $childDirectoryList = Get-ChildItem -LiteralPath $currentDirectory -Directory -ErrorAction Stop
            } catch {
                # Directory enumeration can fail for permissions; log verbosely and continue
                Write-PSFMessage -Level Verbose -Message "Skipping directory $($currentDirectory) due to $($_.Exception.Message)."
            }

            foreach ($childDirectory in $childDirectoryList) {
                if ($childDirectory.Name -eq ".git") {
                    continue
                }

                $pendingDirectoryQueue.Enqueue($childDirectory.FullName)
            }
        }
    }

    end {
        $repositoryLayoutList.ToArray()
    }
}
