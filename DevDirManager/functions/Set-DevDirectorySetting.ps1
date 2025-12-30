function Set-DevDirectorySetting {
    <#
    .SYNOPSIS
        Configures the DevDirManager system settings.

    .DESCRIPTION
        Sets the system-level configuration for automated synchronization including
        the central repository list path, local development directory, and sync options.

        Settings are persisted directly to a JSON file within the PowerShell data folder:
        - Windows PowerShell 5.1: %LOCALAPPDATA%\Microsoft\Windows\PowerShell\DevDirManagerConfiguration.json
        - PowerShell 7+: %LOCALAPPDATA%\Microsoft\PowerShell\DevDirManagerConfiguration.json

        When AutoSyncEnabled is modified, the scheduled task is automatically
        registered or unregistered to maintain consistency.

        Use -Reset to restore all settings to their default values.

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
        When enabled, the scheduled sync task will be registered automatically.
        When disabled, the scheduled sync task will be unregistered.

    .PARAMETER SyncIntervalMinutes
        Interval in minutes between automatic sync operations (for scheduled task).
        Must be a positive integer between 1 and 1440 (24 hours).
        Default: 360 (6 hours).

    .PARAMETER Reset
        Resets all settings to their default values. This creates a new configuration
        file with default values, replacing any existing configuration.
        Cannot be combined with other setting parameters.

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

        Enables automatic sync every 30 minutes. This also registers the scheduled task.

    .EXAMPLE
        PS C:\> Set-DevDirectorySetting -AutoSyncEnabled $false

        Disables automatic sync and unregisters the scheduled task.

    .EXAMPLE
        PS C:\> Set-DevDirectorySetting -Reset

        Resets all settings to default values, creating a fresh configuration.

    .EXAMPLE
        PS C:\> Set-DevDirectorySetting -RepositoryListPath "C:\Backup\repos.json" -WhatIf

        Shows what would be saved without making changes.

    .NOTES
        Version   : 2.1.0
        Author    : Andi Bellstedt, Copilot
        Date      : 2025-12-30
        Keywords  : Configuration, Settings, Sync

    .LINK
        https://github.com/AndiBellstedt/DevDirManager

    #>
    [CmdletBinding(
        SupportsShouldProcess = $true,
        ConfirmImpact = "Medium",
        DefaultParameterSetName = "Default"
    )]
    [OutputType([PSCustomObject])]
    param(
        [Parameter(ParameterSetName = "Default", ValueFromPipelineByPropertyName = $true)]
        [string]
        $RepositoryListPath,

        [Parameter(ParameterSetName = "Default", ValueFromPipelineByPropertyName = $true)]
        [string]
        $LocalDevDirectory,

        [Parameter(ParameterSetName = "Default", ValueFromPipelineByPropertyName = $true)]
        [bool]
        $AutoSyncEnabled,

        [Parameter(ParameterSetName = "Default", ValueFromPipelineByPropertyName = $true)]
        [ValidateRange(1, 1440)]
        [int]
        $SyncIntervalMinutes,

        [Parameter(ParameterSetName = "Reset", Mandatory = $true)]
        [switch]
        $Reset,

        [Parameter()]
        [switch]
        $PassThru
    )

    begin {
        Write-PSFMessage -Level Debug -String "SetDevDirectorySetting.Start" -Tag "SetDevDirectorySetting", "Start"

        #region -- Define default configuration values

        # These are the hard-coded defaults for all settings.
        $script:defaultConfig = [ordered]@{
            RepositoryListPath  = ""
            LocalDevDirectory   = ""
            AutoSyncEnabled     = $false
            SyncIntervalMinutes = 360
            LastSyncTime        = $null
            LastSyncResult      = ""
        }

        #endregion Define default configuration values
    }

    process {
        # Get the settings file path from PSFConfig (this is static, set during module load).
        $settingsPath = Get-PSFConfigValue -FullName "DevDirManager.SettingsPath"
        $settingsDir = Split-Path -Path $settingsPath -Parent

        #region -- Handle Reset parameter set

        if ($PSCmdlet.ParameterSetName -eq "Reset") {
            $target = Get-PSFLocalizedString -Module "DevDirManager" -Name "SetDevDirectorySetting.ShouldProcess.Target"
            $action = "Reset all settings to default values"

            if ($PSCmdlet.ShouldProcess($target, $action)) {
                # Ensure directory exists.
                if (-not (Test-Path -Path $settingsDir -PathType Container)) {
                    $null = New-Item -Path $settingsDir -ItemType Directory -Force
                    Write-PSFMessage -Level Verbose -String "SetDevDirectorySetting.DirectoryCreated" -StringValues @($settingsDir) -Tag "SetDevDirectorySetting", "Directory"
                }

                # Write default configuration.
                $jsonContent = $script:defaultConfig | ConvertTo-Json -Depth 3
                Write-ConfigFileWithRetry -Path $settingsPath -Content $jsonContent

                Write-PSFMessage -Level Verbose -String "SetDevDirectorySetting.Complete" -StringValues @($settingsPath) -Tag "SetDevDirectorySetting", "Complete"
            }

            if ($PassThru) {
                Get-DevDirectorySetting
            }
            return
        }

        #endregion Handle Reset parameter set

        #region -- Load current configuration or create defaults

        $currentConfig = $null

        if (Test-Path -Path $settingsPath -PathType Leaf) {
            try {
                $jsonContent = Get-Content -Path $settingsPath -Raw -Encoding UTF8
                $currentConfig = $jsonContent | ConvertFrom-Json

                # Convert to ordered hashtable for easier manipulation.
                $configData = [ordered]@{}
                foreach ($prop in $currentConfig.PSObject.Properties) {
                    $configData[$prop.Name] = $prop.Value
                }
                $currentConfig = $configData
            } catch {
                Write-PSFMessage -Level Warning -String "SetDevDirectorySetting.ReadFailed" -StringValues @($settingsPath, $_.Exception.Message) -Tag "SetDevDirectorySetting", "Warning"
                # Start with defaults if file is corrupted.
                $currentConfig = $script:defaultConfig.Clone()
            }
        } else {
            # No existing config - start with defaults.
            $currentConfig = $script:defaultConfig.Clone()
        }

        # Ensure all required keys exist (in case old config is missing new keys).
        foreach ($key in $script:defaultConfig.Keys) {
            if (-not $currentConfig.Contains($key)) {
                $currentConfig[$key] = $script:defaultConfig[$key]
            }
        }

        #endregion Load current configuration or create defaults

        #region -- Validate paths if provided

        # Security validation: Check for path traversal patterns in provided paths.
        # The module's UnsafeRelativePathPattern detects path traversal (..) which is a security concern.
        $pathTraversalPattern = [regex]::new('\.{2}')

        if ($PSBoundParameters.ContainsKey("RepositoryListPath") -and -not [string]::IsNullOrWhiteSpace($RepositoryListPath)) {
            # Normalize relative paths to absolute paths using .NET GetFullPath.
            # This handles paths like "./" or "../" and converts them to fully qualified paths.
            $RepositoryListPath = [System.IO.Path]::GetFullPath($RepositoryListPath)
            $PSBoundParameters["RepositoryListPath"] = $RepositoryListPath
            Write-PSFMessage -Level Debug -String "SetDevDirectorySetting.PathNormalized" -StringValues @("RepositoryListPath", $RepositoryListPath) -Tag "SetDevDirectorySetting", "Normalization"

            # Validate security: reject paths containing path traversal sequences after normalization.
            if ($pathTraversalPattern.IsMatch($RepositoryListPath)) {
                Stop-PSFFunction -Message (Get-PSFLocalizedString -Module "DevDirManager" -Name "SetDevDirectorySetting.PathTraversalError") -StringValues @("RepositoryListPath", $RepositoryListPath) -EnableException $true -Category SecurityError -Tag "SetDevDirectorySetting", "Security"
                return
            }

            Write-PSFMessage -Level Verbose -String "SetDevDirectorySetting.PathValidation" -StringValues @($RepositoryListPath) -Tag "SetDevDirectorySetting", "Validation"
            if (-not (Test-Path -Path $RepositoryListPath -PathType Leaf)) {
                Write-PSFMessage -Level Warning -String "SetDevDirectorySetting.PathNotFound" -StringValues @($RepositoryListPath) -Tag "SetDevDirectorySetting", "Warning"
            }
        }

        if ($PSBoundParameters.ContainsKey("LocalDevDirectory") -and -not [string]::IsNullOrWhiteSpace($LocalDevDirectory)) {
            # Normalize relative paths to absolute paths using .NET GetFullPath.
            # This handles paths like "./" or "../" and converts them to fully qualified paths.
            $LocalDevDirectory = [System.IO.Path]::GetFullPath($LocalDevDirectory)
            $PSBoundParameters["LocalDevDirectory"] = $LocalDevDirectory
            Write-PSFMessage -Level Debug -String "SetDevDirectorySetting.PathNormalized" -StringValues @("LocalDevDirectory", $LocalDevDirectory) -Tag "SetDevDirectorySetting", "Normalization"

            # Validate security: reject paths containing path traversal sequences after normalization.
            if ($pathTraversalPattern.IsMatch($LocalDevDirectory)) {
                Stop-PSFFunction -Message (Get-PSFLocalizedString -Module "DevDirManager" -Name "SetDevDirectorySetting.PathTraversalError") -StringValues @("LocalDevDirectory", $LocalDevDirectory) -EnableException $true -Category SecurityError -Tag "SetDevDirectorySetting", "Security"
                return
            }

            Write-PSFMessage -Level Verbose -String "SetDevDirectorySetting.PathValidation" -StringValues @($LocalDevDirectory) -Tag "SetDevDirectorySetting", "Validation"
            if (-not (Test-Path -Path $LocalDevDirectory -PathType Container)) {
                Write-PSFMessage -Level Warning -String "SetDevDirectorySetting.PathNotFound" -StringValues @($LocalDevDirectory) -Tag "SetDevDirectorySetting", "Warning"
            }
        }

        #endregion Validate paths if provided

        #region -- Apply parameter changes to configuration

        # Map parameter names to configuration keys.
        $parameterMapping = @{
            "RepositoryListPath"  = "RepositoryListPath"
            "LocalDevDirectory"   = "LocalDevDirectory"
            "AutoSyncEnabled"     = "AutoSyncEnabled"
            "SyncIntervalMinutes" = "SyncIntervalMinutes"
        }

        # Track if AutoSyncEnabled is being changed.
        $autoSyncChanging = $false
        $newAutoSyncValue = $null
        $oldAutoSyncValue = $currentConfig["AutoSyncEnabled"]

        if ($PSBoundParameters.ContainsKey("AutoSyncEnabled")) {
            if ($oldAutoSyncValue -ne $AutoSyncEnabled) {
                $autoSyncChanging = $true
                $newAutoSyncValue = $AutoSyncEnabled
            }
        }

        # Track if any changes are made.
        $hasChanges = $false

        # Process each parameter that was provided.
        foreach ($paramName in $parameterMapping.Keys) {
            if ($PSBoundParameters.ContainsKey($paramName)) {
                $configKey = $parameterMapping[$paramName]
                $value = $PSBoundParameters[$paramName]

                # ShouldProcess check for each setting change.
                $target = Get-PSFLocalizedString -Module "DevDirManager" -Name "SetDevDirectorySetting.ShouldProcess.Target"
                $action = Get-PSFLocalizedString -Module "DevDirManager" -Name "SetDevDirectorySetting.ShouldProcess.Action"
                $action = $action -f $paramName, $value

                if ($PSCmdlet.ShouldProcess($target, $action)) {
                    $currentConfig[$configKey] = $value
                    Write-PSFMessage -Level Verbose -String "SetDevDirectorySetting.ConfigUpdated" -StringValues @($paramName, $value) -Tag "SetDevDirectorySetting", "Update"
                    $hasChanges = $true
                }
            }
        }

        #endregion Apply parameter changes to configuration

        #region -- Handle AutoSyncEnabled changes (register/unregister scheduled task)

        if ($autoSyncChanging -and -not $WhatIfPreference -and $hasChanges) {
            if ($newAutoSyncValue -eq $true) {
                # Register the scheduled task.
                try {
                    Register-DevDirectoryScheduledSync -Force
                    Write-PSFMessage -Level Important -Message "Scheduled task registered for automatic synchronization" -Tag "SetDevDirectorySetting", "ScheduledTask"
                } catch {
                    # Rollback the AutoSyncEnabled setting on failure.
                    $currentConfig["AutoSyncEnabled"] = $false
                    Stop-PSFFunction -Message "Failed to register scheduled task: $_" -Tag "SetDevDirectorySetting", "Error" -EnableException $true -ErrorRecord $_
                    return
                }
            } else {
                # Unregister the scheduled task.
                try {
                    Unregister-DevDirectoryScheduledSync
                    Write-PSFMessage -Level Important -Message "Scheduled task unregistered" -Tag "SetDevDirectorySetting", "ScheduledTask"
                } catch {
                    # Rollback the AutoSyncEnabled setting on failure.
                    $currentConfig["AutoSyncEnabled"] = $true
                    Stop-PSFFunction -Message "Failed to unregister scheduled task: $_" -Tag "SetDevDirectorySetting", "Error" -EnableException $true -ErrorRecord $_
                    return
                }
            }
        }

        #endregion Handle AutoSyncEnabled changes (register/unregister scheduled task)

        #region -- Persist configuration to JSON file

        if ($hasChanges -and -not $WhatIfPreference) {
            # Ensure directory exists.
            if (-not (Test-Path -Path $settingsDir -PathType Container)) {
                $null = New-Item -Path $settingsDir -ItemType Directory -Force
                Write-PSFMessage -Level Verbose -String "SetDevDirectorySetting.DirectoryCreated" -StringValues @($settingsDir) -Tag "SetDevDirectorySetting", "Directory"
            }

            # Convert datetime to ISO 8601 string for JSON serialization if present.
            $exportConfig = [ordered]@{}
            foreach ($key in $currentConfig.Keys) {
                $value = $currentConfig[$key]
                if ($value -is [datetime]) {
                    $exportConfig[$key] = $value.ToString("o")
                } else {
                    $exportConfig[$key] = $value
                }
            }

            # Write configuration to JSON file with retry logic.
            $jsonContent = $exportConfig | ConvertTo-Json -Depth 3
            Write-ConfigFileWithRetry -Path $settingsPath -Content $jsonContent

            Write-PSFMessage -Level Verbose -String "SetDevDirectorySetting.Persisted" -StringValues @($settingsPath) -Tag "SetDevDirectorySetting", "Persistence"
        }

        #endregion Persist configuration to JSON file

        #region -- Return updated settings if PassThru

        if ($PassThru) {
            Get-DevDirectorySetting
        }

        #endregion Return updated settings if PassThru
    }

    end {
        Write-PSFMessage -Level Debug -String "SetDevDirectorySetting.Complete" -Tag "SetDevDirectorySetting", "Complete"
    }
}
