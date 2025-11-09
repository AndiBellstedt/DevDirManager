function Get-DevDirectoryRemoteUrl {
    <#
    .SYNOPSIS
        Internal helper that extracts the remote URL from a Git repository's configuration.

    .DESCRIPTION
        Parses the .git/config file of a Git repository to locate the URL for a specific remote name.
        This function is used internally by Get-DevDirectory to gather repository metadata without
        invoking external git commands, improving performance when scanning many repositories.

    .PARAMETER RepositoryPath
        The full path to the Git repository root directory (the folder containing .git).

    .PARAMETER RemoteName
        The name of the Git remote to query (typically "origin").

    .OUTPUTS
        [string] The remote URL if found; otherwise $null.

    .EXAMPLE
        PS C:\> Get-DevDirectoryRemoteUrl -RepositoryPath "C:\Repos\MyProject" -RemoteName "origin"

        Returns the URL for the "origin" remote of the Git repository at C:\Repos\MyProject.

    .NOTES
        Author    : Andi Bellstedt, Copilot
        Date      : 2025-11-09
        Version   : 1.0.2
        Keywords  : Git, Internal, Helper

    #>
    [CmdletBinding()]
    [OutputType([string])]
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

    Write-PSFMessage -Level Debug -Message "Extracting remote URL for '$($RemoteName)' from repository: '$($RepositoryPath)'" -Tag "GetDevDirectoryRemoteUrl", "Start"

    # Build the path to the repository's Git configuration file
    $gitFolderPath = Join-Path -Path $RepositoryPath -ChildPath ".git"
    $gitConfigPath = Join-Path -Path $gitFolderPath -ChildPath "config"
    Write-PSFMessage -Level Debug -Message "Git config path: '$($gitConfigPath)'" -Tag "GetDevDirectoryRemoteUrl", "PathResolution"

    # Validate that the config file exists before attempting to parse it
    if (-not (Test-Path -LiteralPath $gitConfigPath -PathType Leaf)) {
        # Use PSFramework logging to provide consistent output handling across the module
        Write-PSFMessage -Level Verbose -String 'GetDevDirectoryRemoteUrl.ConfigMissing' -StringValues @($gitConfigPath)
        Write-PSFMessage -Level Verbose -Message "Git config file not found, returning null" -Tag "GetDevDirectoryRemoteUrl", "Result"
        return $null
    }

    Write-PSFMessage -Level Debug -Message "Reading git config file" -Tag "GetDevDirectoryRemoteUrl", "FileRead"

    # Read the entire configuration file into memory for parsing
    # Git config files are typically small (a few KB), so this is efficient
    $configLineList = Get-Content -LiteralPath $gitConfigPath -ErrorAction Stop

    # Build a regex pattern to match the [remote "name"] section header
    # Escape the remote name to handle special regex characters safely
    $escapedRemoteName = [Regex]::Escape($RemoteName)
    $sectionPattern = "^\s*\[remote\s+`"$($escapedRemoteName)`"\]\s*$"
    Write-PSFMessage -Level Debug -Message "Searching for section pattern: '$($sectionPattern)'" -Tag "GetDevDirectoryRemoteUrl", "Parse"

    # Track whether we are currently parsing lines within the target remote section
    $insideTargetSection = $false

    # Parse the config line-by-line using a simple state machine approach
    foreach ($line in $configLineList) {
        # Check if this line is a section header (e.g., [remote "origin"])
        if ($line -match "^\s*\[.+\]\s*$") {
            # Update the state: are we now inside the target remote section?
            $insideTargetSection = ($line -match $sectionPattern)
            if ($insideTargetSection) {
                Write-PSFMessage -Level Debug -Message "Found [remote `"$($RemoteName)`"] section in git config" -Tag "GetDevDirectoryRemoteUrl", "Parse"
            }
            continue
        }

        # If we are inside the target section and find a "url = <value>" line, extract the URL
        if ($insideTargetSection -and $line -match "^\s*url\s*=\s*(.+)$") {
            # Return the captured URL value, trimmed of leading/trailing whitespace
            $remoteUrl = $matches[1].Trim()
            Write-PSFMessage -Level Verbose -Message "Remote URL for '$($RemoteName)': '$($remoteUrl)'" -Tag "GetDevDirectoryRemoteUrl", "Result"
            return $remoteUrl
        }
    }

    # If we reach here, the remote was not found or it has no URL configured
    Write-PSFMessage -Level Verbose -Message "Remote '$($RemoteName)' not found or has no URL configured" -Tag "GetDevDirectoryRemoteUrl", "Result"
    return $null
}
