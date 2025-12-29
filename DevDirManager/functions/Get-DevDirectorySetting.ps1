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

        This function reads directly from the JSON file to ensure consistency.
        If any discrepancy is detected between the file and in-memory configuration,
        a warning is displayed and the file values take precedence.

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
        Version   : 1.1.0
        Author    : Andi Bellstedt, Copilot
        Date      : 2025-12-29
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

        $configPath = Get-DevDirectoryConfigPath
        $configFromFile = $null

        if (Test-Path -Path $configPath -PathType Leaf) {
            try {
                $configFromFile = Get-Content -Path $configPath -Raw -ErrorAction Stop | ConvertFrom-Json -ErrorAction Stop
            } catch {
                Write-PSFMessage -Level Error -String "GetDevDirectorySetting.ReadFailed" -StringValues @($configPath, $_) -Tag "GetDevDirectorySetting", "Error"
            }
        } else {
            Write-PSFMessage -Level Error -String "GetDevDirectorySetting.FileNotFound" -StringValues @($configPath) -Tag "GetDevDirectorySetting", "Error"
        }

        #endregion Load configuration from JSON file

        #region -- Build configuration values from file (with fallback to PSFConfig)

        # Read values from file, falling back to PSFConfig if not in file.
        $configValues = @{
            RepositoryListPath  = if ($configFromFile -and $null -ne $configFromFile.RepositoryListPath) { $configFromFile.RepositoryListPath } else { Get-PSFConfigValue -FullName "DevDirManager.System.RepositoryListPath" }
            LocalDevDirectory   = if ($configFromFile -and $null -ne $configFromFile.LocalDevDirectory) { $configFromFile.LocalDevDirectory } else { Get-PSFConfigValue -FullName "DevDirManager.System.LocalDevDirectory" }
            AutoSyncEnabled     = if ($configFromFile -and $null -ne $configFromFile.AutoSyncEnabled) { [bool]$configFromFile.AutoSyncEnabled } else { Get-PSFConfigValue -FullName "DevDirManager.System.AutoSyncEnabled" }
            SyncIntervalMinutes = if ($configFromFile -and $null -ne $configFromFile.SyncIntervalMinutes) { [int]$configFromFile.SyncIntervalMinutes } else { Get-PSFConfigValue -FullName "DevDirManager.System.SyncIntervalMinutes" }
            LastSyncTime        = $null
            LastSyncResult      = if ($configFromFile -and $null -ne $configFromFile.LastSyncResult) { $configFromFile.LastSyncResult } else { Get-PSFConfigValue -FullName "DevDirManager.System.LastSyncResult" }
        }

        # Handle LastSyncTime datetime conversion.
        if ($configFromFile -and $configFromFile.LastSyncTime -is [string] -and -not [string]::IsNullOrWhiteSpace($configFromFile.LastSyncTime)) {
            try {
                $configValues.LastSyncTime = [datetime]::Parse($configFromFile.LastSyncTime)
            } catch {
                $configValues.LastSyncTime = $null
            }
        } else {
            $configValues.LastSyncTime = Get-PSFConfigValue -FullName "DevDirManager.System.LastSyncTime"
        }

        #endregion Build configuration values from file (with fallback to PSFConfig)

        #region -- Check for inconsistencies and update PSFConfig if needed

        # Compare file values with in-memory PSFConfig values and update if different.
        $psfConfigValues = @{
            RepositoryListPath  = Get-PSFConfigValue -FullName "DevDirManager.System.RepositoryListPath"
            LocalDevDirectory   = Get-PSFConfigValue -FullName "DevDirManager.System.LocalDevDirectory"
            AutoSyncEnabled     = Get-PSFConfigValue -FullName "DevDirManager.System.AutoSyncEnabled"
            SyncIntervalMinutes = Get-PSFConfigValue -FullName "DevDirManager.System.SyncIntervalMinutes"
            LastSyncTime        = Get-PSFConfigValue -FullName "DevDirManager.System.LastSyncTime"
            LastSyncResult      = Get-PSFConfigValue -FullName "DevDirManager.System.LastSyncResult"
        }

        foreach ($key in $configValues.Keys) {
            $fileValue = $configValues[$key]
            $memValue = $psfConfigValues[$key]

            # Normalize nulls for comparison.
            $fileNormalized = if ($null -eq $fileValue) { "" } else { $fileValue }
            $memNormalized = if ($null -eq $memValue) { "" } else { $memValue }

            if ($fileNormalized -ne $memNormalized) {
                Write-PSFMessage -Level Warning -String "GetDevDirectorySetting.Inconsistency" -StringValues @($key, $memNormalized, $fileNormalized) -Tag "GetDevDirectorySetting", "Inconsistency"

                # Update PSFConfig with file value (disable handler to avoid circular write).
                Set-PSFConfig -Module "DevDirManager" -Name "System.$key" -Value $fileValue -DisableHandler
            }
        }

        #endregion Check for inconsistencies and update PSFConfig if needed

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
