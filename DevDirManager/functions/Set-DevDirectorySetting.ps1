function Set-DevDirectorySetting {
    <#
    .SYNOPSIS
        Configures the DevDirManager system settings.

    .DESCRIPTION
        Sets the system-level configuration for automated synchronization including
        the central repository list path, local development directory, and sync options.

        Settings are persisted to a JSON file within the PowerShell data folder
        automatically via the PSFramework configuration handler system:
        - Windows PowerShell 5.1: %LOCALAPPDATA%\Microsoft\Windows\PowerShell\DevDirManagerConfiguration.json
        - PowerShell 7+: %LOCALAPPDATA%\Microsoft\PowerShell\DevDirManagerConfiguration.json

        When AutoSyncEnabled is modified, the scheduled task is automatically
        registered or unregistered to maintain consistency.

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
        PS C:\> Set-DevDirectorySetting -RepositoryListPath "C:\Backup\repos.json" -WhatIf

        Shows what would be saved without making changes.

    .NOTES
        Version   : 1.1.0
        Author    : Andi Bellstedt, Copilot
        Date      : 2025-12-29
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

        [Parameter()]
        [switch]
        $PassThru
    )

    begin {
        Write-PSFMessage -Level Debug -String "SetDevDirectorySetting.Start" -Tag "SetDevDirectorySetting", "Start"
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
        }

        # Track if AutoSyncEnabled is being changed.
        $autoSyncChanging = $false
        $newAutoSyncValue = $null

        if ($PSBoundParameters.ContainsKey("AutoSyncEnabled")) {
            $currentAutoSync = Get-PSFConfigValue -FullName "DevDirManager.System.AutoSyncEnabled"
            if ($currentAutoSync -ne $AutoSyncEnabled) {
                $autoSyncChanging = $true
                $newAutoSyncValue = $AutoSyncEnabled
            }
        }

        # Process each parameter that was provided.
        foreach ($paramName in $parameterMapping.Keys) {
            if ($PSBoundParameters.ContainsKey($paramName)) {
                $psfKey = $parameterMapping[$paramName]
                $value = $PSBoundParameters[$paramName]

                # ShouldProcess check for each setting change.
                $target = Get-PSFLocalizedString -Module "DevDirManager" -Name "SetDevDirectorySetting.ShouldProcess.Target"
                $action = Get-PSFLocalizedString -Module "DevDirManager" -Name "SetDevDirectorySetting.ShouldProcess.Action"
                $action = $action -f $paramName, $value

                if ($PSCmdlet.ShouldProcess($target, $action)) {
                    # For AutoSyncEnabled changes, we need special handling to prevent handler recursion.
                    if ($paramName -eq "AutoSyncEnabled") {
                        # Disable handler to prevent recursive scheduled task registration.
                        Set-PSFConfig -Module "DevDirManager" -Name $psfKey -Value $value -DisableHandler
                    } else {
                        # Normal setting update (handler will auto-persist to JSON).
                        Set-PSFConfig -Module "DevDirManager" -Name $psfKey -Value $value
                    }

                    Write-PSFMessage -Level Verbose -String "SetDevDirectorySetting.ConfigUpdated" -StringValues @($paramName, $value) -Tag "SetDevDirectorySetting", "Update"
                }
            }
        }

        #endregion Update PSFramework configuration

        #region -- Handle AutoSyncEnabled changes (register/unregister scheduled task)

        if ($autoSyncChanging -and -not $WhatIfPreference) {
            if ($newAutoSyncValue -eq $true) {
                # Register the scheduled task.
                try {
                    Register-DevDirectoryScheduledSync -Force
                    Write-PSFMessage -Level Important -String "SetDevDirectorySetting.AutoSyncEnabled.Registered" -Tag "SetDevDirectorySetting", "ScheduledTask"
                } catch {
                    # Rollback the AutoSyncEnabled setting on failure.
                    Set-PSFConfig -Module "DevDirManager" -Name "System.AutoSyncEnabled" -Value $false -DisableHandler
                    Stop-PSFFunction -Message "Failed to register scheduled task: $_" -Tag "SetDevDirectorySetting", "Error" -EnableException $true -ErrorRecord $_
                    return
                }
            } else {
                # Unregister the scheduled task.
                try {
                    Unregister-DevDirectoryScheduledSync
                    Write-PSFMessage -Level Important -String "SetDevDirectorySetting.AutoSyncEnabled.Unregistered" -Tag "SetDevDirectorySetting", "ScheduledTask"
                } catch {
                    # Rollback the AutoSyncEnabled setting on failure.
                    Set-PSFConfig -Module "DevDirManager" -Name "System.AutoSyncEnabled" -Value $true -DisableHandler
                    Stop-PSFFunction -Message "Failed to unregister scheduled task: $_" -Tag "SetDevDirectorySetting", "Error" -EnableException $true -ErrorRecord $_
                    return
                }
            }

            # After successful task management, persist the AutoSyncEnabled value manually.
            # We need to trigger the handler manually since we disabled it above.
            $configPath = Get-DevDirectoryConfigPath
            $configDir = Split-Path -Path $configPath -Parent
            if (-not (Test-Path -Path $configDir -PathType Container)) {
                $null = New-Item -Path $configDir -ItemType Directory -Force
            }

            $configExport = [ordered]@{
                RepositoryListPath  = Get-PSFConfigValue -FullName "DevDirManager.System.RepositoryListPath"
                LocalDevDirectory   = Get-PSFConfigValue -FullName "DevDirManager.System.LocalDevDirectory"
                AutoSyncEnabled     = Get-PSFConfigValue -FullName "DevDirManager.System.AutoSyncEnabled"
                SyncIntervalMinutes = Get-PSFConfigValue -FullName "DevDirManager.System.SyncIntervalMinutes"
                LastSyncTime        = Get-PSFConfigValue -FullName "DevDirManager.System.LastSyncTime"
                LastSyncResult      = Get-PSFConfigValue -FullName "DevDirManager.System.LastSyncResult"
            }

            if ($configExport.LastSyncTime -is [datetime]) {
                $configExport.LastSyncTime = $configExport.LastSyncTime.ToString("o")
            }

            $configExport | ConvertTo-Json -Depth 3 | Set-Content -Path $configPath -Encoding UTF8 -Force
        }

        #endregion Handle AutoSyncEnabled changes (register/unregister scheduled task)

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
