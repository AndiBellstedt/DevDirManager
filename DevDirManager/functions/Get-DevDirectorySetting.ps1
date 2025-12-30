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

        This function reads directly from the JSON file.

    .PARAMETER Name
        Optional. Retrieves a specific setting by name.
        Valid values: RepositoryListPath, LocalDevDirectory, AutoSyncEnabled,
        SyncIntervalMinutes, LastSyncTime, LastSyncResult, All, *

        Use "All" or "*" to explicitly request all settings (same as omitting the parameter).
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
        PS C:\> Get-DevDirectorySetting -Name All

        Explicitly returns all settings (equivalent to omitting -Name).

    .EXAMPLE
        PS C:\> Get-DevDirectorySetting -Name *

        Returns all settings using wildcard notation (common PS practice).

    .EXAMPLE
        PS C:\> Get-DevDirectorySetting | Format-List

        Returns all settings and displays them in list format for detailed view.

    .NOTES
        Version   : 2.0.0
        Author    : Andi Bellstedt, Copilot
        Date      : 2025-12-30
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
            "LastSyncTime",
            "LastSyncResult",
            "All",
            "*"
        )]
        [string]
        $Name
    )

    begin {
        Write-PSFMessage -Level Debug -String "GetDevDirectorySetting.Start" -Tag "GetDevDirectorySetting", "Start"
    }

    process {
        #region -- Load configuration from JSON file

        # Get the settings file path from PSFConfig (static path set during module load).
        $settingsPath = Get-PSFConfigValue -FullName "DevDirManager.SettingsPath"

        if (-not (Test-Path -Path $settingsPath -PathType Leaf)) {
            Stop-PSFFunction -Message (Get-PSFLocalizedString -Module "DevDirManager" -Name "GetDevDirectorySetting.FileNotFound") -StringValues @($settingsPath) -EnableException $true -Category ObjectNotFound -Tag "GetDevDirectorySetting", "Error"
            return
        }

        try {
            $configFromFile = Get-Content -Path $settingsPath -Raw -Encoding UTF8 -ErrorAction Stop | ConvertFrom-Json -ErrorAction Stop
        } catch {
            Stop-PSFFunction -Message (Get-PSFLocalizedString -Module "DevDirManager" -Name "GetDevDirectorySetting.ReadFailed") -StringValues @($settingsPath, $_.Exception.Message) -EnableException $true -ErrorRecord $_ -Tag "GetDevDirectorySetting", "Error"
            return
        }

        #endregion Load configuration from JSON file

        #region -- Build configuration values from file

        # Build the configuration values hashtable from the JSON file.
        # Due to proper error handling above, $configFromFile is guaranteed to exist and be valid.
        $configValues = @{
            RepositoryListPath  = $configFromFile.RepositoryListPath
            LocalDevDirectory   = $configFromFile.LocalDevDirectory
            AutoSyncEnabled     = [bool]$configFromFile.AutoSyncEnabled
            SyncIntervalMinutes = [int]$configFromFile.SyncIntervalMinutes
            LastSyncTime        = $null
            LastSyncResult      = $configFromFile.LastSyncResult
        }

        # Handle LastSyncTime datetime conversion from ISO 8601 string.
        if ($configFromFile.LastSyncTime -is [string] -and -not [string]::IsNullOrWhiteSpace($configFromFile.LastSyncTime)) {
            try {
                $configValues.LastSyncTime = [datetime]::Parse($configFromFile.LastSyncTime)
            } catch {
                Write-PSFMessage -Level Error -Message "Failed to parse LastSyncTime: $($configFromFile.LastSyncTime)" -Tag "GetDevDirectorySetting", "DateParse"
                $configValues.LastSyncTime = $null
            }
        }

        #endregion Build configuration values from file

        #region -- Return requested data

        # Check if a specific single value is requested (not "All" or "*").
        if ($PSBoundParameters.ContainsKey("Name") -and -not [string]::IsNullOrWhiteSpace($Name) -and $Name -ne "All" -and $Name -ne "*") {
            # Return only the single requested value.
            Write-PSFMessage -Level Verbose -String "GetDevDirectorySetting.ReturnSingleValue" -StringValues @($Name) -Tag "GetDevDirectorySetting", "SingleValue"
            $configValues[$Name]
        } else {
            # Return the full settings object (when no Name specified, or Name is "All" or "*").
            $settingObject = [PSCustomObject]@{
                PSTypeName          = "DevDirManager.SystemSetting"
                ComputerName        = $env:COMPUTERNAME
                SettingsPath        = $settingsPath
                RepositoryListPath  = $configValues.RepositoryListPath
                LocalDevDirectory   = $configValues.LocalDevDirectory
                AutoSyncEnabled     = $configValues.AutoSyncEnabled
                SyncIntervalMinutes = $configValues.SyncIntervalMinutes
                LastSyncTime        = $configValues.LastSyncTime
                LastSyncResult      = $configValues.LastSyncResult
            }

            Write-PSFMessage -Level Verbose -String "GetDevDirectorySetting.Complete" -StringValues @($env:COMPUTERNAME) -Tag "GetDevDirectorySetting", "Complete"
            $settingObject
        }

        #endregion Return requested data
    }

    end {
        Write-PSFMessage -Level Debug -String "GetDevDirectorySetting.End" -Tag "GetDevDirectorySetting", "End"
    }
}
