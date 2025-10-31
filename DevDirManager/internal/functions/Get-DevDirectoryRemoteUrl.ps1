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
        Date      : 2025-10-31
        Version   : 1.0.1
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

    # Build the path to the repository's Git configuration file
    $gitFolderPath = Join-Path -Path $RepositoryPath -ChildPath ".git"
    $gitConfigPath = Join-Path -Path $gitFolderPath -ChildPath "config"

    # Validate that the config file exists before attempting to parse it
    if (-not (Test-Path -LiteralPath $gitConfigPath -PathType Leaf)) {
        # Use PSFramework logging to provide consistent output handling across the module
        Write-PSFMessage -Level Verbose -String 'GetDevDirectoryRemoteUrl.ConfigMissing' -StringValues @($gitConfigPath)
        return $null
    }

    # Read the entire configuration file into memory for parsing
    # Git config files are typically small (a few KB), so this is efficient
    $configLineList = Get-Content -LiteralPath $gitConfigPath -ErrorAction Stop

    # Build a regex pattern to match the [remote "name"] section header
    # Escape the remote name to handle special regex characters safely
    $escapedRemoteName = [Regex]::Escape($RemoteName)
    $sectionPattern = "^\s*\[remote\s+`"$($escapedRemoteName)`"\]\s*$"

    # Track whether we are currently parsing lines within the target remote section
    $insideTargetSection = $false

    # Parse the config line-by-line using a simple state machine approach
    foreach ($line in $configLineList) {
        # Check if this line is a section header (e.g., [remote "origin"])
        if ($line -match "^\s*\[.+\]\s*$") {
            # Update the state: are we now inside the target remote section?
            $insideTargetSection = ($line -match $sectionPattern)
            continue
        }

        # If we are inside the target section and find a "url = <value>" line, extract the URL
        if ($insideTargetSection -and $line -match "^\s*url\s*=\s*(.+)$") {
            # Return the captured URL value, trimmed of leading/trailing whitespace
            return $matches[1].Trim()
        }
    }

    # If we reach here, the remote was not found or it has no URL configured
    return $null
}
