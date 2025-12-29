function Invoke-DevDirectorySync {
    <#
    .SYNOPSIS
        Synchronizes repositories using the configured system settings.

    .DESCRIPTION
        Convenience function that reads the system configuration and invokes
        Sync-DevDirectoryList with the configured paths and filter settings.
        Applies the SystemFilter property to include only matching repositories
        for the current computer.

        Requires system settings to be configured via Set-DevDirectorySetting first.
        The function reads the RepositoryListPath and LocalDevDirectory from the
        system configuration, then applies system-based filtering before syncing.

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

    .PARAMETER Confirm
        Prompts you for confirmation before running the cmdlet.

    .EXAMPLE
        PS C:\> Invoke-DevDirectorySync

        Runs sync using system configuration with computer-based filtering.

    .EXAMPLE
        PS C:\> Invoke-DevDirectorySync -WhatIf

        Preview what would be synchronized on this computer.

    .EXAMPLE
        PS C:\> Invoke-DevDirectorySync -PassThru | Format-Table

        Syncs repositories and displays the results in a table.

    .EXAMPLE
        PS C:\> Invoke-DevDirectorySync -SkipExisting -ShowGitOutput

        Syncs repositories, skipping existing ones and showing git output.

    .NOTES
        Version   : 1.0.0
        Author    : Andi Bellstedt, Copilot
        Date      : 2025-12-28
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
        Write-PSFMessage -Level Debug -String "InvokeDevDirectorySync.Start" -StringValues @($env:COMPUTERNAME) -Tag "InvokeDevDirectorySync", "Start"

        #region -- Validate system configuration

        $settings = Get-DevDirectorySetting

        if ([string]::IsNullOrWhiteSpace($settings.RepositoryListPath)) {
            Stop-PSFFunction -Message (Get-PSFLocalizedString -Module "DevDirManager" -Name "InvokeDevDirectorySync.NotConfigured.RepositoryListPath") -EnableException $true -Category InvalidOperation -Tag "InvokeDevDirectorySync", "Configuration"
            return
        }

        if ([string]::IsNullOrWhiteSpace($settings.LocalDevDirectory)) {
            Stop-PSFFunction -Message (Get-PSFLocalizedString -Module "DevDirManager" -Name "InvokeDevDirectorySync.NotConfigured.LocalDevDirectory") -EnableException $true -Category InvalidOperation -Tag "InvokeDevDirectorySync", "Configuration"
            return
        }

        if (-not (Test-Path -Path $settings.RepositoryListPath -PathType Leaf)) {
            Stop-PSFFunction -Message (Get-PSFLocalizedString -Module "DevDirManager" -Name "InvokeDevDirectorySync.RepositoryListNotFound") -StringValues @($settings.RepositoryListPath) -EnableException $true -Category ObjectNotFound -Tag "InvokeDevDirectorySync", "Configuration"
            return
        }

        #endregion Validate system configuration
    }

    process {
        if (Test-PSFFunctionInterrupt) { return }

        #region -- Execute sync with filtering

        $syncTarget = "Sync repositories from '$($settings.RepositoryListPath)'"
        if ($PSCmdlet.ShouldProcess($settings.LocalDevDirectory, $syncTarget)) {
            # Import repository list from the configured path.
            $allRepositoryList = Import-DevDirectoryList -FilePath $settings.RepositoryListPath

            # Apply system filter to each repository.
            # Repositories with a SystemFilter property use that value; others use the default.
            $filteredRepositoryList = $allRepositoryList | Where-Object {
                $filterValue = if ($_.SystemFilter) { $_.SystemFilter } else { $settings.DefaultSystemFilter }
                Test-DevDirectorySystemFilter -SystemFilter $filterValue
            }

            $totalCount = ($allRepositoryList | Measure-Object).Count
            $filteredCount = ($filteredRepositoryList | Measure-Object).Count

            Write-PSFMessage -Level Host -String "InvokeDevDirectorySync.FilterApplied" -StringValues @($filteredCount, $totalCount, $env:COMPUTERNAME) -Tag "InvokeDevDirectorySync", "Filter"

            if ($filteredCount -eq 0) {
                Write-PSFMessage -Level Warning -String "InvokeDevDirectorySync.NoMatchingRepositories" -StringValues @($env:COMPUTERNAME) -Tag "InvokeDevDirectorySync", "Warning"
                return
            }

            # Create temporary file with filtered repositories for sync.
            $tempFile = [System.IO.Path]::GetTempFileName()
            $tempFile = [System.IO.Path]::ChangeExtension($tempFile, ".json")

            try {
                # Export filtered repositories to temporary file.
                $filteredRepositoryList | Export-DevDirectoryList -FilePath $tempFile -Force

                # Build sync parameters.
                $syncParams = @{
                    DirectoryPath      = $settings.LocalDevDirectory
                    RepositoryListPath = $tempFile
                }

                if ($Force) { $syncParams["Force"] = $true }
                if ($SkipExisting) { $syncParams["SkipExisting"] = $true }
                if ($ShowGitOutput) { $syncParams["ShowGitOutput"] = $true }
                if ($PassThru) { $syncParams["PassThru"] = $true }

                # Execute the sync operation.
                $result = Sync-DevDirectoryList @syncParams

                # Update last sync time and result in PSFramework config.
                $syncTime = Get-Date
                Set-PSFConfig -Module "DevDirManager" -Name "System.LastSyncTime" -Value $syncTime
                Set-PSFConfig -Module "DevDirManager" -Name "System.LastSyncResult" -Value "Success"

                # Persist updated sync status to config file.
                $configPath = Get-DevDirectoryConfigPath
                $configExport = [ordered]@{
                    RepositoryListPath  = $settings.RepositoryListPath
                    LocalDevDirectory   = $settings.LocalDevDirectory
                    AutoSyncEnabled     = $settings.AutoSyncEnabled
                    SyncIntervalMinutes = $settings.SyncIntervalMinutes
                    DefaultSystemFilter = $settings.DefaultSystemFilter
                    LastSyncTime        = $syncTime.ToString("o")
                    LastSyncResult      = "Success"
                }
                $configExport | ConvertTo-Json -Depth 3 | Set-Content -Path $configPath -Encoding UTF8 -Force

                Write-PSFMessage -Level Host -String "InvokeDevDirectorySync.Complete" -StringValues @($filteredCount) -Tag "InvokeDevDirectorySync", "Complete"

                if ($PassThru) {
                    $result
                }
            } catch {
                # Update failure status in configuration.
                Set-PSFConfig -Module "DevDirManager" -Name "System.LastSyncResult" -Value "Failed: $($_)"

                $configPath = Get-DevDirectoryConfigPath
                if (Test-Path -Path $configPath) {
                    try {
                        $existingConfig = Get-Content -Path $configPath -Raw | ConvertFrom-Json
                        $configExport = [ordered]@{
                            RepositoryListPath  = $existingConfig.RepositoryListPath
                            LocalDevDirectory   = $existingConfig.LocalDevDirectory
                            AutoSyncEnabled     = $existingConfig.AutoSyncEnabled
                            SyncIntervalMinutes = $existingConfig.SyncIntervalMinutes
                            DefaultSystemFilter = $existingConfig.DefaultSystemFilter
                            LastSyncTime        = $existingConfig.LastSyncTime
                            LastSyncResult      = "Failed: $($_)"
                        }
                        $configExport | ConvertTo-Json -Depth 3 | Set-Content -Path $configPath -Encoding UTF8 -Force
                    } catch {
                        # Ignore config update failures during error handling.
                        Write-PSFMessage -Level Debug -Message "Failed to update config file during error handling: $($_)"
                    }
                }

                throw
            } finally {
                # Clean up temporary file.
                if (Test-Path -Path $tempFile) {
                    Remove-Item -Path $tempFile -Force -ErrorAction SilentlyContinue
                }
            }
        }

        #endregion Execute sync with filtering
    }

    end {
        # No cleanup needed.
    }
}
