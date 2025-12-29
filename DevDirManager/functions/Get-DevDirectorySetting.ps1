function Get-DevDirectorySetting {
    <#
    .SYNOPSIS
        Retrieves the DevDirManager system configuration.

    .DESCRIPTION
        Returns the current system-level configuration including the repository
        list path, local development directory, and sync settings.

        Configuration is stored in a JSON file within the PowerShell data folder:
        - Windows PowerShell 5.1: %LOCALAPPDATA%\Microsoft\Windows\PowerShell\DevDirManagerConfiguration.json
        - PowerShell 7+: %LOCALAPPDATA%\Microsoft\PowerShell\DevDirManagerConfiguration.json

        The configuration enables automated synchronization of repositories across
        multiple computers using system-based filtering.

    .PARAMETER Name
        Optional. Retrieves a specific setting by name.
        Valid values: RepositoryListPath, LocalDevDirectory, AutoSyncEnabled,
        SyncIntervalMinutes, DefaultSystemFilter, LastSyncTime, LastSyncResult, ConfigFilePath

        If omitted, returns all settings as a single DevDirManager.SystemSetting object.

    .EXAMPLE
        PS C:\> Get-DevDirectorySetting

        Returns all DevDirManager system settings as a DevDirManager.SystemSetting object.

    .EXAMPLE
        PS C:\> Get-DevDirectorySetting -Name RepositoryListPath

        Returns only the repository list path setting value.

    .EXAMPLE
        PS C:\> Get-DevDirectorySetting -Name AutoSyncEnabled

        Returns whether automatic synchronization is enabled.

    .EXAMPLE
        PS C:\> Get-DevDirectorySetting -Name ConfigFilePath

        Returns the path to the configuration file for the current PowerShell version.

    .EXAMPLE
        PS C:\> Get-DevDirectorySetting | Format-List

        Returns all settings and displays them in list format for detailed view.

    .NOTES
        Version   : 1.0.0
        Author    : Andi Bellstedt, Copilot
        Date      : 2025-12-28
        Keywords  : Configuration, Settings, Sync

    .LINK
        https://github.com/AndiBellstedt/DevDirManager

    #>
    [CmdletBinding()]
    [OutputType([PSCustomObject])]
    param(
        [Parameter(
            Position = 0,
            ValueFromPipeline = $true,
            ValueFromPipelineByPropertyName = $true
        )]
        [ValidateSet(
            "RepositoryListPath",
            "LocalDevDirectory",
            "AutoSyncEnabled",
            "SyncIntervalMinutes",
            "DefaultSystemFilter",
            "LastSyncTime",
            "LastSyncResult",
            "ConfigFilePath"
        )]
        [string]
        $Name
    )

    begin {
        Write-PSFMessage -Level Debug -String "GetDevDirectorySetting.Start" -Tag "GetDevDirectorySetting", "Start"
    }

    process {
        #region -- Retrieve configuration values from PSFramework

        # Build a hashtable with all configuration values.
        $configValues = @{
            RepositoryListPath  = Get-PSFConfigValue -FullName "DevDirManager.System.RepositoryListPath"
            LocalDevDirectory   = Get-PSFConfigValue -FullName "DevDirManager.System.LocalDevDirectory"
            AutoSyncEnabled     = Get-PSFConfigValue -FullName "DevDirManager.System.AutoSyncEnabled"
            SyncIntervalMinutes = Get-PSFConfigValue -FullName "DevDirManager.System.SyncIntervalMinutes"
            DefaultSystemFilter = Get-PSFConfigValue -FullName "DevDirManager.System.DefaultSystemFilter"
            LastSyncTime        = Get-PSFConfigValue -FullName "DevDirManager.System.LastSyncTime"
            LastSyncResult      = Get-PSFConfigValue -FullName "DevDirManager.System.LastSyncResult"
            ConfigFilePath      = Get-PSFConfigValue -FullName "DevDirManager.System.ConfigFilePath"
        }

        #endregion Retrieve configuration values from PSFramework

        #region -- Return requested data

        if ($PSBoundParameters.ContainsKey("Name")) {
            # Return only the single requested value.
            Write-PSFMessage -Level Debug -String "GetDevDirectorySetting.ReturnSingleValue" -StringValues @($Name) -Tag "GetDevDirectorySetting", "SingleValue"
            $configValues[$Name]
        } else {
            # Return the full settings object.
            $settingObject = [PSCustomObject]@{
                PSTypeName          = "DevDirManager.SystemSetting"
                RepositoryListPath  = $configValues.RepositoryListPath
                LocalDevDirectory   = $configValues.LocalDevDirectory
                AutoSyncEnabled     = $configValues.AutoSyncEnabled
                SyncIntervalMinutes = $configValues.SyncIntervalMinutes
                DefaultSystemFilter = $configValues.DefaultSystemFilter
                LastSyncTime        = $configValues.LastSyncTime
                LastSyncResult      = $configValues.LastSyncResult
                ConfigFilePath      = $configValues.ConfigFilePath
                ComputerName        = $env:COMPUTERNAME
            }

            Write-PSFMessage -Level Debug -String "GetDevDirectorySetting.Complete" -StringValues @($env:COMPUTERNAME) -Tag "GetDevDirectorySetting", "Complete"
            $settingObject
        }

        #endregion Return requested data
    }

    end {
        # No cleanup needed.
    }
}
