function Get-DevDirectoryUserInfo {
    <#
    .SYNOPSIS
        Internal helper that extracts repository-local user.name and user.email from a Git repository.

    .DESCRIPTION
        Parses the .git/config file of a Git repository to locate the user.name and user.email values
        configured at the repository level (ignoring global and system-level git configuration).
        This function is used internally by Get-DevDirectory to gather repository-specific user metadata.

    .PARAMETER RepositoryPath
        The full path to the Git repository root directory (the folder containing .git).

    .OUTPUTS
        [hashtable] A hashtable with 'UserName' and 'UserEmail' keys; values are $null if not configured.

    .EXAMPLE
        PS C:\> Get-DevDirectoryUserInfo -RepositoryPath "C:\Repos\MyProject"

        Returns a hashtable with UserName and UserEmail from the repository's local .git/config.

    .NOTES
        Author    : Andi Bellstedt, Copilot
        Date      : 2025-11-09
        Version   : 1.0.1
        Keywords  : Git, Internal, Helper

    #>
    [CmdletBinding()]
    [OutputType([hashtable])]
    param(
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]
        $RepositoryPath
    )

    Write-PSFMessage -Level Debug -String 'GetDevDirectoryUserInfo.Start' -StringValues @($RepositoryPath) -Tag "GetDevDirectoryUserInfo", "Start"

    # Build the path to the repository's Git configuration file
    $gitFolderPath = Join-Path -Path $RepositoryPath -ChildPath ".git"
    $gitConfigPath = Join-Path -Path $gitFolderPath -ChildPath "config"
    Write-PSFMessage -Level Debug -String 'GetDevDirectoryUserInfo.ConfigPath' -StringValues @($gitConfigPath) -Tag "GetDevDirectoryUserInfo", "PathResolution"

    # Initialize result with null values
    $result = @{
        UserName  = $null
        UserEmail = $null
    }

    # Validate that the config file exists before attempting to parse it
    if (-not (Test-Path -LiteralPath $gitConfigPath -PathType Leaf)) {
        Write-PSFMessage -Level Verbose -String 'GetDevDirectoryUserInfo.ConfigMissing' -StringValues @($gitConfigPath)
        Write-PSFMessage -Level Verbose -String 'GetDevDirectoryUserInfo.ConfigNotFound' -Tag "GetDevDirectoryUserInfo", "Result"
        return $result
    }

    Write-PSFMessage -Level Debug -String 'GetDevDirectoryUserInfo.ReadingConfig' -Tag "GetDevDirectoryUserInfo", "FileRead"

    # Read the entire configuration file into memory for parsing
    # Git config files are typically small (a few KB), so this is efficient
    $configLineList = Get-Content -LiteralPath $gitConfigPath -ErrorAction Stop

    # Track whether we are currently parsing lines within the [user] section
    $insideUserSection = $false

    # Parse the config line-by-line using a simple state machine approach
    foreach ($line in $configLineList) {
        # Check if this line is a section header (e.g., [user])
        if ($line -match "^\s*\[(.+)\]\s*$") {
            # Update the state: are we now inside the [user] section?
            $insideUserSection = ($matches[1] -eq "user")
            if ($insideUserSection) {
                Write-PSFMessage -Level Debug -String 'GetDevDirectoryUserInfo.SectionFound' -Tag "GetDevDirectoryUserInfo", "Parse"
            }
            continue
        }

        # If we are inside the [user] section, extract name and email
        if ($insideUserSection) {
            if ($line -match "^\s*name\s*=\s*(.+)$") {
                $result.UserName = $matches[1].Trim()
                Write-PSFMessage -Level Debug -String 'GetDevDirectoryUserInfo.UserNameFound' -StringValues @($result.UserName) -Tag "GetDevDirectoryUserInfo", "Parse"
            } elseif ($line -match "^\s*email\s*=\s*(.+)$") {
                $result.UserEmail = $matches[1].Trim()
                Write-PSFMessage -Level Debug -String 'GetDevDirectoryUserInfo.UserEmailFound' -StringValues @($result.UserEmail) -Tag "GetDevDirectoryUserInfo", "Parse"
            }
        }
    }

    Write-PSFMessage -Level Verbose -String 'GetDevDirectoryUserInfo.Result' -StringValues @($result.UserName, $result.UserEmail) -Tag "GetDevDirectoryUserInfo", "Result"
    return $result
}
