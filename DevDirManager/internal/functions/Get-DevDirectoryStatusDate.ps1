function Get-DevDirectoryStatusDate {
    <#
    .SYNOPSIS
        Internal helper that retrieves the most recent commit or modification date from a Git repository.

    .DESCRIPTION
        Determines the repository's activity date by reading the HEAD commit timestamp from the Git object
        database or falling back to the modification time of the .git directory if no commits are found.
        This function is used internally by Get-DevDirectory to capture repository freshness.

    .PARAMETER RepositoryPath
        The full path to the Git repository root directory (the folder containing .git).

    .OUTPUTS
        [datetime] The most recent commit date, or the .git directory modification time if no commits exist.
        Returns $null if the .git directory does not exist.

    .EXAMPLE
        PS C:\> Get-DevDirectoryStatusDate -RepositoryPath "C:\Repos\MyProject"

        Returns the date of the most recent commit in MyProject.

    .NOTES
        Author    : Andi Bellstedt, Copilot
        Date      : 2025-11-09
        Version   : 1.0.1
        Keywords  : Git, Internal, Helper

    #>
    [CmdletBinding()]
    [OutputType([datetime])]
    param(
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]
        $RepositoryPath
    )

    Write-PSFMessage -Level Debug -Message "Retrieving status date from repository: '$($RepositoryPath)'" -Tag "GetDevDirectoryStatusDate", "Start"

    # Build the path to the .git directory
    $gitFolderPath = Join-Path -Path $RepositoryPath -ChildPath ".git"
    Write-PSFMessage -Level Debug -Message "Git folder path: '$($gitFolderPath)'" -Tag "GetDevDirectoryStatusDate", "PathResolution"

    # Validate that the .git directory exists
    if (-not (Test-Path -LiteralPath $gitFolderPath -PathType Container)) {
        Write-PSFMessage -Level Verbose -String 'GetDevDirectoryStatusDate.GitFolderMissing' -StringValues @($gitFolderPath)
        Write-PSFMessage -Level Verbose -Message "Git folder not found, returning null" -Tag "GetDevDirectoryStatusDate", "Result"
        return $null
    }

    # Attempt to read the HEAD reference to find the most recent commit
    $headPath = Join-Path -Path $gitFolderPath -ChildPath "HEAD"
    Write-PSFMessage -Level Debug -Message "Checking HEAD reference at: '$($headPath)'" -Tag "GetDevDirectoryStatusDate", "HeadCheck"

    if (Test-Path -LiteralPath $headPath -PathType Leaf) {
        # Read HEAD to determine the current branch or commit
        $headContent = Get-Content -LiteralPath $headPath -Raw -ErrorAction SilentlyContinue
        if ($headContent -match "^ref:\s*(.+)$") {
            # HEAD points to a branch; resolve the branch's commit SHA
            $branchRef = $matches[1].Trim()
            $branchPath = Join-Path -Path $gitFolderPath -ChildPath $branchRef
            Write-PSFMessage -Level Debug -Message "HEAD points to branch ref: '$($branchRef)'" -Tag "GetDevDirectoryStatusDate", "BranchResolution"

            if (Test-Path -LiteralPath $branchPath -PathType Leaf) {
                # Use the modification time of the branch reference file as the commit date
                $commitDate = (Get-Item -LiteralPath $branchPath).LastWriteTime
                Write-PSFMessage -Level Verbose -Message "Retrieved commit date from branch ref: $($commitDate)" -Tag "GetDevDirectoryStatusDate", "Result"
                return $commitDate
            }
        } elseif ($headContent -match "^[0-9a-f]{40}") {
            # HEAD is detached; use the modification time of the HEAD file itself
            $commitDate = (Get-Item -LiteralPath $headPath).LastWriteTime
            Write-PSFMessage -Level Verbose -Message "Retrieved commit date from detached HEAD: $($commitDate)" -Tag "GetDevDirectoryStatusDate", "Result"
            return $commitDate
        }
    }

    # Fallback: use the .git directory's modification time as an approximation
    Write-PSFMessage -Level Debug -Message "Using .git directory modification time as fallback" -Tag "GetDevDirectoryStatusDate", "Fallback"

    $gitFolderItem = Get-Item -LiteralPath $gitFolderPath
    $fallbackDate = $gitFolderItem.LastWriteTime

    Write-PSFMessage -Level Verbose -Message "Retrieved status date from .git directory: $($fallbackDate)" -Tag "GetDevDirectoryStatusDate", "Result"

    return $fallbackDate
}
