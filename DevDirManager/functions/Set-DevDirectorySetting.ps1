function Set-DevDirectorySetting {
    <#
    .SYNOPSIS
        Configures the DevDirManager system settings.

    .DESCRIPTION
        Sets the system-level configuration for automated synchronization including
        the central repository list path, local development directory, and sync options.

        Settings are persisted to a JSON file within the PowerShell data folder:
        - Windows PowerShell 5.1: %LOCALAPPDATA%\Microsoft\Windows\PowerShell\DevDirManagerConfiguration.json
        - PowerShell 7+: %LOCALAPPDATA%\Microsoft\PowerShell\DevDirManagerConfiguration.json

        The configuration enables automated synchronization of repositories across
        multiple computers using system-based filtering.

    .PARAMETER RepositoryListPath
        Path to the central repository list file (JSON, CSV, or XML).
        Supports UNC paths for network shares, enabling centralized repository
        management across multiple computers.

    .PARAMETER LocalDevDirectory
        Local directory where repositories should be synchronized.
        This is the root directory where the folder structure from the
        repository list will be recreated.

    .PARAMETER AutoSyncEnabled
        Enables or disables automatic synchronization.
        When enabled, the scheduled sync task will actively synchronize repositories.

    .PARAMETER SyncIntervalMinutes
        Interval in minutes between automatic sync operations (for scheduled task).
        Must be a positive integer between 1 and 1440 (24 hours).

    .PARAMETER DefaultSystemFilter
        Default filter pattern for this computer. Repositories without a SystemFilter
        property will use this pattern for matching.

        Pattern syntax:
        - "*" matches all systems (default)
        - "WORKSTATION-01" exact match
        - "DEV-*" wildcard match (starts with DEV-)
        - "!SERVER-*" exclusion pattern (NOT on SERVER-* machines)
        - "DEV-*,LAPTOP-*" multiple patterns (OR logic)

    .PARAMETER PassThru
        Returns the updated configuration object after saving.

    .PARAMETER WhatIf
        Shows what would happen if the cmdlet runs. The cmdlet is not run.

    .PARAMETER Confirm
        Prompts you for confirmation before running the cmdlet.

    .EXAMPLE
        PS C:\> Set-DevDirectorySetting -RepositoryListPath "\\server\dev\repos.json" -LocalDevDirectory "C:\Development"

        Configures the basic sync paths for automated synchronization.

    .EXAMPLE
        PS C:\> Set-DevDirectorySetting -AutoSyncEnabled $true -SyncIntervalMinutes 30

        Enables automatic sync every 30 minutes.

    .EXAMPLE
        PS C:\> Set-DevDirectorySetting -DefaultSystemFilter "DEV-*,LAPTOP-*" -PassThru

        Sets the system filter to match computers starting with "DEV-" or "LAPTOP-"
        and returns the updated configuration.

    .EXAMPLE
        PS C:\> Set-DevDirectorySetting -RepositoryListPath "C:\Backup\repos.json" -WhatIf

        Shows what would be saved without making changes.

    .NOTES
        Version   : 1.0.0
        Author    : Andi Bellstedt, Copilot
        Date      : 2025-12-28
        Keywords  : Configuration, Settings, Sync

    .LINK
        https://github.com/AndiBellstedt/DevDirManager

    #>
    [CmdletBinding(
        SupportsShouldProcess = $true,
        ConfirmImpact = "Medium"
    )]
    [OutputType([PSCustomObject])]
    param(
        [Parameter(ValueFromPipelineByPropertyName = $true)]
        [string]
        $RepositoryListPath,

        [Parameter(ValueFromPipelineByPropertyName = $true)]
        [string]
        $LocalDevDirectory,

        [Parameter(ValueFromPipelineByPropertyName = $true)]
        [bool]
        $AutoSyncEnabled,

        [Parameter(ValueFromPipelineByPropertyName = $true)]
        [ValidateRange(1, 1440)]
        [int]
        $SyncIntervalMinutes,

        [Parameter(ValueFromPipelineByPropertyName = $true)]
        [string]
        $DefaultSystemFilter,

        [Parameter()]
        [switch]
        $PassThru
    )

    begin {
        Write-PSFMessage -Level Debug -String "SetDevDirectorySetting.Start" -Tag "SetDevDirectorySetting", "Start"

        # Get configuration file path (respects PS version).
        $configPath = Get-DevDirectoryConfigPath
    }

    process {
        #region -- Validate paths if provided

        if ($PSBoundParameters.ContainsKey("RepositoryListPath") -and -not [string]::IsNullOrWhiteSpace($RepositoryListPath)) {
            Write-PSFMessage -Level Verbose -String "SetDevDirectorySetting.PathValidation" -StringValues @($RepositoryListPath) -Tag "SetDevDirectorySetting", "Validation"
            if (-not (Test-Path -Path $RepositoryListPath -PathType Leaf)) {
                Write-PSFMessage -Level Warning -String "SetDevDirectorySetting.PathNotFound" -StringValues @($RepositoryListPath) -Tag "SetDevDirectorySetting", "Warning"
            }
        }

        if ($PSBoundParameters.ContainsKey("LocalDevDirectory") -and -not [string]::IsNullOrWhiteSpace($LocalDevDirectory)) {
            Write-PSFMessage -Level Verbose -String "SetDevDirectorySetting.PathValidation" -StringValues @($LocalDevDirectory) -Tag "SetDevDirectorySetting", "Validation"
            if (-not (Test-Path -Path $LocalDevDirectory -PathType Container)) {
                Write-PSFMessage -Level Warning -String "SetDevDirectorySetting.PathNotFound" -StringValues @($LocalDevDirectory) -Tag "SetDevDirectorySetting", "Warning"
            }
        }

        #endregion Validate paths if provided

        #region -- Update PSFramework configuration

        # Map parameter names to PSFramework configuration keys.
        $parameterMapping = @{
            "RepositoryListPath"  = "System.RepositoryListPath"
            "LocalDevDirectory"   = "System.LocalDevDirectory"
            "AutoSyncEnabled"     = "System.AutoSyncEnabled"
            "SyncIntervalMinutes" = "System.SyncIntervalMinutes"
            "DefaultSystemFilter" = "System.DefaultSystemFilter"
        }

        foreach ($paramName in $parameterMapping.Keys) {
            if ($PSBoundParameters.ContainsKey($paramName)) {
                $psfKey = $parameterMapping[$paramName]
                $value = $PSBoundParameters[$paramName]

                Set-PSFConfig -Module "DevDirManager" -Name $psfKey -Value $value
                Write-PSFMessage -Level Verbose -String "SetDevDirectorySetting.ConfigUpdated" -StringValues @($paramName, $value) -Tag "SetDevDirectorySetting", "Update"
            }
        }

        # Update config file path in case it changed (PS version switch scenario).
        Set-PSFConfig -Module "DevDirManager" -Name "System.ConfigFilePath" -Value $configPath

        #endregion Update PSFramework configuration

        #region -- Persist configuration to JSON file

        if ($PSCmdlet.ShouldProcess($configPath, "Save configuration")) {
            # Ensure directory exists.
            $configDir = Split-Path -Path $configPath -Parent
            if (-not (Test-Path -Path $configDir -PathType Container)) {
                $null = New-Item -Path $configDir -ItemType Directory -Force
                Write-PSFMessage -Level Verbose -String "SetDevDirectorySetting.DirectoryCreated" -StringValues @($configDir) -Tag "SetDevDirectorySetting", "Directory"
            }

            # Build configuration object for export.
            $configExport = [ordered]@{
                RepositoryListPath  = Get-PSFConfigValue -FullName "DevDirManager.System.RepositoryListPath"
                LocalDevDirectory   = Get-PSFConfigValue -FullName "DevDirManager.System.LocalDevDirectory"
                AutoSyncEnabled     = Get-PSFConfigValue -FullName "DevDirManager.System.AutoSyncEnabled"
                SyncIntervalMinutes = Get-PSFConfigValue -FullName "DevDirManager.System.SyncIntervalMinutes"
                DefaultSystemFilter = Get-PSFConfigValue -FullName "DevDirManager.System.DefaultSystemFilter"
                LastSyncTime        = Get-PSFConfigValue -FullName "DevDirManager.System.LastSyncTime"
                LastSyncResult      = Get-PSFConfigValue -FullName "DevDirManager.System.LastSyncResult"
            }

            # Convert datetime to ISO 8601 string for JSON serialization.
            if ($configExport.LastSyncTime -is [datetime]) {
                $configExport.LastSyncTime = $configExport.LastSyncTime.ToString("o")
            }

            # Write the configuration to JSON file.
            $configExport | ConvertTo-Json -Depth 3 | Set-Content -Path $configPath -Encoding UTF8 -Force

            Write-PSFMessage -Level Verbose -String "SetDevDirectorySetting.Persisted" -StringValues @($configPath) -Tag "SetDevDirectorySetting", "Persisted"
        }

        #endregion Persist configuration to JSON file

        #region -- Return result if requested

        if ($PassThru) {
            Get-DevDirectorySetting
        }

        Write-PSFMessage -Level Debug -String "SetDevDirectorySetting.Complete" -Tag "SetDevDirectorySetting", "Complete"

        #endregion Return result if requested
    }

    end {
        # No cleanup needed.
    }
}
