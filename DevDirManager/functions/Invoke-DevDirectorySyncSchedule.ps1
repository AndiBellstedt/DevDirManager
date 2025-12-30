function Invoke-DevDirectorySyncSchedule {
    <#
    .SYNOPSIS
        Synchronizes repositories using the configured system settings.

    .DESCRIPTION
        Convenience function that reads the system configuration and invokes
        Sync-DevDirectoryList with the configured paths. Applies the SystemFilter
        property from each repository to include only matching repositories
        for the current computer.

        Requires system settings to be configured via Set-DevDirectorySetting first.
        The function reads the RepositoryListPath and LocalDevDirectory from the
        system configuration, then applies per-repository filtering before syncing.

        Each repository in the list can have a SystemFilter property that determines
        which computers should sync that repository. Repositories without a
        SystemFilter property will sync to all systems (equivalent to "*").

        This function is designed for automated synchronization scenarios, such as
        scheduled tasks or logon scripts, where the sync should happen without
        requiring manual path specification each time.

    .PARAMETER Force
        Forces the sync operation, overwriting local changes if necessary.
        Forwards to Sync-DevDirectoryList.

    .PARAMETER SkipExisting
        Skips repositories that already exist locally.
        Forwards to Sync-DevDirectoryList.

    .PARAMETER ShowGitOutput
        Displays git command output during sync operations.
        Forwards to Sync-DevDirectoryList.

    .PARAMETER PassThru
        Returns the synchronized repository list.

    .PARAMETER WhatIf
        Shows what would happen if the cmdlet runs. The cmdlet is not run.
        In WhatIf mode, the filtering is still performed and a summary is shown,
        but no actual synchronization occurs and LastSync settings are not updated.

    .PARAMETER Confirm
        Prompts you for confirmation before running the cmdlet.

    .EXAMPLE
        PS C:\> Invoke-DevDirectorySyncSchedule

        Runs sync using system configuration with computer-based filtering.

    .EXAMPLE
        PS C:\> Invoke-DevDirectorySyncSchedule -WhatIf

        Preview what would be synchronized on this computer.

    .EXAMPLE
        PS C:\> Invoke-DevDirectorySyncSchedule -PassThru | Format-Table

        Syncs repositories and displays the results in a table.

    .EXAMPLE
        PS C:\> Invoke-DevDirectorySyncSchedule -SkipExisting -ShowGitOutput

        Syncs repositories, skipping existing ones and showing git output.

    .NOTES
        Version   : 2.0.1
        Author    : Andi Bellstedt, Copilot
        Date      : 2025-12-30
        Keywords  : Git, Sync, Repository, Automation

    .LINK
        https://github.com/AndiBellstedt/DevDirManager

    #>
    [CmdletBinding(
        SupportsShouldProcess = $true,
        ConfirmImpact = "Medium"
    )]
    [OutputType([PSCustomObject[]])]
    param(
        [Parameter()]
        [switch]
        $Force,

        [Parameter()]
        [switch]
        $SkipExisting,

        [Parameter()]
        [switch]
        $ShowGitOutput,

        [Parameter()]
        [switch]
        $PassThru
    )

    begin {
        Write-PSFMessage -Level Debug -String "InvokeDevDirectorySyncSchedule.Start" -StringValues @($env:COMPUTERNAME) -Tag "InvokeDevDirectorySyncSchedule", "Start"

        #region -- Validate system configuration using Get-DevDirectorySetting

        $repoListPath = Get-DevDirectorySetting -Name "RepositoryListPath"
        $localDevDir = Get-DevDirectorySetting -Name "LocalDevDirectory"
        $settingsPath = Get-PSFConfigValue -FullName "DevDirManager.SettingsPath"
        $currentSettings = Get-DevDirectorySetting

        if ([string]::IsNullOrWhiteSpace($repoListPath)) {
            Stop-PSFFunction -Message (Get-PSFLocalizedString -Module "DevDirManager" -Name "InvokeDevDirectorySyncSchedule.NotConfigured.RepositoryListPath") -EnableException $true -Category InvalidOperation -Tag "InvokeDevDirectorySyncSchedule", "Configuration"
            return
        }

        if ([string]::IsNullOrWhiteSpace($localDevDir)) {
            Stop-PSFFunction -Message (Get-PSFLocalizedString -Module "DevDirManager" -Name "InvokeDevDirectorySyncSchedule.NotConfigured.LocalDevDirectory") -EnableException $true -Category InvalidOperation -Tag "InvokeDevDirectorySyncSchedule", "Configuration"
            return
        }

        if (-not (Test-Path -Path $repoListPath -PathType Leaf)) {
            Stop-PSFFunction -Message (Get-PSFLocalizedString -Module "DevDirManager" -Name "InvokeDevDirectorySyncSchedule.RepositoryListNotFound") -StringValues @($repoListPath) -EnableException $true -Category ObjectNotFound -Tag "InvokeDevDirectorySyncSchedule", "Configuration"
            return
        }

        #endregion Validate system configuration
    }

    process {
        if (Test-PSFFunctionInterrupt) { return }

        #region -- Import and filter repositories

        # Import repository list from the configured path.
        $allRepositoryList = Import-DevDirectoryList -FilePath $repoListPath

        # Apply system filter to each repository.
        # Each repository can have a SystemFilter property; if absent, defaults to "*" (all systems).
        $filteredRepositoryList = $allRepositoryList | Where-Object {
            $filterValue = if ($_.SystemFilter) { $_.SystemFilter } else { "*" }
            Test-DevDirectorySystemFilter -SystemFilter $filterValue
        }

        $totalCount = ($allRepositoryList | Measure-Object).Count
        $filteredCount = ($filteredRepositoryList | Measure-Object).Count

        Write-PSFMessage -Level Verbose -String "InvokeDevDirectorySyncSchedule.FilterApplied" -StringValues @($filteredCount, $totalCount, $env:COMPUTERNAME) -Tag "InvokeDevDirectorySyncSchedule", "Filter"

        if ($filteredCount -eq 0) {
            Write-PSFMessage -Level Warning -String "InvokeDevDirectorySyncSchedule.NoMatchingRepositories" -StringValues @($env:COMPUTERNAME) -Tag "InvokeDevDirectorySyncSchedule", "Warning"
            return
        }

        #endregion Import and filter repositories

        #region -- Execute sync operation

        # Get localized ShouldProcess text.
        $shouldProcessTarget = Get-PSFLocalizedString -Module "DevDirManager" -Name "InvokeDevDirectorySyncSchedule.ShouldProcess.Target"
        $shouldProcessAction = (Get-PSFLocalizedString -Module "DevDirManager" -Name "InvokeDevDirectorySyncSchedule.ShouldProcess.Action") -f $filteredCount, $localDevDir

        if ($PSCmdlet.ShouldProcess($shouldProcessTarget, $shouldProcessAction)) {
            # Create temporary file with filtered repositories for sync.
            $tempFile = [System.IO.Path]::GetTempFileName()
            $tempFile = [System.IO.Path]::ChangeExtension($tempFile, ".json")

            try {
                # Export filtered repositories to temporary file.
                $filteredRepositoryList | Export-DevDirectoryList -FilePath $tempFile -Force

                # Build sync parameters.
                $syncParams = @{
                    DirectoryPath      = $localDevDir
                    RepositoryListPath = $tempFile
                }

                if ($Force) { $syncParams["Force"] = $true }
                if ($SkipExisting) { $syncParams["SkipExisting"] = $true }
                if ($ShowGitOutput) { $syncParams["ShowGitOutput"] = $true }
                if ($PassThru) { $syncParams["PassThru"] = $true }

                # Execute the sync operation.
                $result = Sync-DevDirectoryList @syncParams

                # Update last sync time and result using internal helper function.
                $syncTime = Get-Date

                # Prepare updated config.
                $configExport = [ordered]@{
                    RepositoryListPath  = $currentSettings.RepositoryListPath
                    LocalDevDirectory   = $currentSettings.LocalDevDirectory
                    AutoSyncEnabled     = $currentSettings.AutoSyncEnabled
                    SyncIntervalMinutes = $currentSettings.SyncIntervalMinutes
                    LastSyncTime        = $syncTime.ToString("o")
                    LastSyncResult      = "Success: $filteredCount repositories"
                }

                # Write with internal helper function for proper retry logic.
                $jsonContent = $configExport | ConvertTo-Json -Depth 3
                Write-ConfigFileWithRetry -Path $settingsPath -Content $jsonContent

                Write-PSFMessage -Level Host -String "InvokeDevDirectorySyncSchedule.Complete" -StringValues @($filteredCount) -Tag "InvokeDevDirectorySyncSchedule", "Complete"

                if ($PassThru) { $result }
            } catch {
                # Update failure status in configuration.
                $errorMessage = "Failed: $_"

                # Persist failure status to JSON file using internal helper function.
                try {
                    $configExport = [ordered]@{
                        RepositoryListPath  = $currentSettings.RepositoryListPath
                        LocalDevDirectory   = $currentSettings.LocalDevDirectory
                        AutoSyncEnabled     = $currentSettings.AutoSyncEnabled
                        SyncIntervalMinutes = $currentSettings.SyncIntervalMinutes
                        LastSyncTime        = if ($currentSettings.LastSyncTime) { $currentSettings.LastSyncTime.ToString("o") } else { $null }
                        LastSyncResult      = $errorMessage
                    }
                    $jsonContent = $configExport | ConvertTo-Json -Depth 3
                    Write-ConfigFileWithRetry -Path $settingsPath -Content $jsonContent
                } catch {
                    Write-PSFMessage -Level Error -String "InvokeDevDirectorySyncSchedule.ConfigUpdateFailed" -StringValues @($errorMessage) -Tag "InvokeDevDirectorySyncSchedule", "Error" -ErrorRecord $_
                }
            } finally {
                # Clean up temporary file (always, even in WhatIf mode).
                if (Test-Path -Path $tempFile) { Remove-Item -Path $tempFile -Force -ErrorAction SilentlyContinue }
            }
        }

        #endregion Execute sync operation
    }

    end {
        Write-PSFMessage -Level Debug -String "InvokeDevDirectorySyncSchedule.End" -Tag "InvokeDevDirectorySyncSchedule", "End"
    }
}
