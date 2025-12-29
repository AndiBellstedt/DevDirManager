function Get-DevDirectoryConfigPath {
    <#
    .SYNOPSIS
        Gets the path to the DevDirManager configuration file.

    .DESCRIPTION
        Returns the path to the DevDirManager configuration JSON file.
        The path is determined based on the PowerShell version:
        - Windows PowerShell 5.1: %LOCALAPPDATA%\Microsoft\Windows\PowerShell\DevDirManagerConfiguration.json
        - PowerShell 7+: %LOCALAPPDATA%\Microsoft\PowerShell\DevDirManagerConfiguration.json

        This function ensures that the configuration file is stored in the appropriate
        location for the current PowerShell version, respecting the different data
        folder conventions.

    .EXAMPLE
        PS C:\> Get-DevDirectoryConfigPath

        Returns the full path to the configuration file for the current PowerShell version.
        On Windows PowerShell 5.1, this would be:
        C:\Users\<username>\AppData\Local\Microsoft\Windows\PowerShell\DevDirManagerConfiguration.json

    .EXAMPLE
        PS C:\> $configPath = Get-DevDirectoryConfigPath
        PS C:\> Test-Path -Path $configPath

        Gets the configuration file path and checks if it exists.

    .NOTES
        Version   : 1.0.0
        Author    : Andi Bellstedt, Copilot
        Date      : 2025-12-28
        Keywords  : Configuration, Path, Settings

    #>
    [CmdletBinding()]
    [OutputType([string])]
    param()

    begin {
        # No initialization needed for this simple helper function.
    }

    process {
        #region -- Determine PowerShell data folder

        # Check the PowerShell major version to determine the correct path.
        # PowerShell 7+ (Core) uses a different location than Windows PowerShell 5.1.
        if ($PSVersionTable.PSVersion.Major -ge 6) {
            # PowerShell 7+ (Core) stores user data in Microsoft\PowerShell.
            $powerShellDataFolder = Join-Path -Path $env:LOCALAPPDATA -ChildPath "Microsoft\PowerShell"
        } else {
            # Windows PowerShell 5.1 stores user data in Microsoft\Windows\PowerShell.
            $powerShellDataFolder = Join-Path -Path $env:LOCALAPPDATA -ChildPath "Microsoft\Windows\PowerShell"
        }

        #endregion Determine PowerShell data folder

        #region -- Return configuration file path

        # Combine the data folder with the configuration file name.
        Join-Path -Path $powerShellDataFolder -ChildPath "DevDirManagerConfiguration.json"

        #endregion Return configuration file path
    }

    end {
        # No cleanup needed for this simple helper function.
    }
}
