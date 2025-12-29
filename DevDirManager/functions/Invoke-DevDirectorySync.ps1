function Invoke-DevDirectorySync {
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
        Version   : 1.1.0
        Author    : Andi Bellstedt, Copilot
        Date      : 2025-12-29
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

        #region -- Validate system configuration (get values directly from PSFConfig)

        $repoListPath = Get-PSFConfigValue -FullName "DevDirManager.System.RepositoryListPath"
        $localDevDir = Get-PSFConfigValue -FullName "DevDirManager.System.LocalDevDirectory"

        if ([string]::IsNullOrWhiteSpace($repoListPath)) {
            Stop-PSFFunction -Message (Get-PSFLocalizedString -Module "DevDirManager" -Name "InvokeDevDirectorySync.NotConfigured.RepositoryListPath") -EnableException $true -Category InvalidOperation -Tag "InvokeDevDirectorySync", "Configuration"
            return
        }

        if ([string]::IsNullOrWhiteSpace($localDevDir)) {
            Stop-PSFFunction -Message (Get-PSFLocalizedString -Module "DevDirManager" -Name "InvokeDevDirectorySync.NotConfigured.LocalDevDirectory") -EnableException $true -Category InvalidOperation -Tag "InvokeDevDirectorySync", "Configuration"
            return
        }

        if (-not (Test-Path -Path $repoListPath -PathType Leaf)) {
            Stop-PSFFunction -Message (Get-PSFLocalizedString -Module "DevDirManager" -Name "InvokeDevDirectorySync.RepositoryListNotFound") -StringValues @($repoListPath) -EnableException $true -Category ObjectNotFound -Tag "InvokeDevDirectorySync", "Configuration"
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

        Write-PSFMessage -Level Host -String "InvokeDevDirectorySync.FilterApplied" -StringValues @($filteredCount, $totalCount, $env:COMPUTERNAME) -Tag "InvokeDevDirectorySync", "Filter"

        if ($filteredCount -eq 0) {
            Write-PSFMessage -Level Warning -String "InvokeDevDirectorySync.NoMatchingRepositories" -StringValues @($env:COMPUTERNAME) -Tag "InvokeDevDirectorySync", "Warning"
            return
        }

        #endregion Import and filter repositories

        #region -- Execute sync operation

        # Get localized ShouldProcess text.
        $shouldProcessTarget = Get-PSFLocalizedString -Module "DevDirManager" -Name "InvokeDevDirectorySync.ShouldProcess.Target"
        $shouldProcessAction = (Get-PSFLocalizedString -Module "DevDirManager" -Name "InvokeDevDirectorySync.ShouldProcess.Action") -f $filteredCount, $localDevDir

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

                # Update last sync time and result using Set-DevDirectorySetting approach.
                # We use Set-PSFConfig with DisableHandler since we'll manually persist.
                $syncTime = Get-Date
                Set-PSFConfig -Module "DevDirManager" -Name "System.LastSyncTime" -Value $syncTime -DisableHandler
                Set-PSFConfig -Module "DevDirManager" -Name "System.LastSyncResult" -Value "Success: $filteredCount repositories" -DisableHandler

                # Persist sync results to JSON file.
                $configPath = Get-DevDirectoryConfigPath
                $configExport = [ordered]@{
                    RepositoryListPath  = Get-PSFConfigValue -FullName "DevDirManager.System.RepositoryListPath"
                    LocalDevDirectory   = Get-PSFConfigValue -FullName "DevDirManager.System.LocalDevDirectory"
                    AutoSyncEnabled     = Get-PSFConfigValue -FullName "DevDirManager.System.AutoSyncEnabled"
                    SyncIntervalMinutes = Get-PSFConfigValue -FullName "DevDirManager.System.SyncIntervalMinutes"
                    LastSyncTime        = $syncTime.ToString("o")
                    LastSyncResult      = "Success: $filteredCount repositories"
                }
                $configExport | ConvertTo-Json -Depth 3 | Set-Content -Path $configPath -Encoding UTF8 -Force

                Write-PSFMessage -Level Host -String "InvokeDevDirectorySync.Complete" -StringValues @($filteredCount) -Tag "InvokeDevDirectorySync", "Complete"

                if ($PassThru) {
                    $result
                }
            } catch {
                # Update failure status in configuration.
                $errorMessage = "Failed: $_"
                Set-PSFConfig -Module "DevDirManager" -Name "System.LastSyncResult" -Value $errorMessage -DisableHandler

                # Persist failure status to JSON file.
                try {
                    $configPath = Get-DevDirectoryConfigPath
                    if (Test-Path -Path $configPath) {
                        $existingConfig = Get-Content -Path $configPath -Raw | ConvertFrom-Json
                        $configExport = [ordered]@{
                            RepositoryListPath  = $existingConfig.RepositoryListPath
                            LocalDevDirectory   = $existingConfig.LocalDevDirectory
                            AutoSyncEnabled     = $existingConfig.AutoSyncEnabled
                            SyncIntervalMinutes = $existingConfig.SyncIntervalMinutes
                            LastSyncTime        = $existingConfig.LastSyncTime
                            LastSyncResult      = $errorMessage
                        }
                        $configExport | ConvertTo-Json -Depth 3 | Set-Content -Path $configPath -Encoding UTF8 -Force
                    }
                } catch {
                    Write-PSFMessage -Level Debug -String "InvokeDevDirectorySync.ConfigUpdateFailed" -StringValues @($_) -Tag "InvokeDevDirectorySync", "Error"
                }

                throw
            } finally {
                # Clean up temporary file (always, even in WhatIf mode).
                if (Test-Path -Path $tempFile) {
                    Remove-Item -Path $tempFile -Force -ErrorAction SilentlyContinue
                }
            }
        } else {
            # WhatIf mode: Show what would be synced but don't modify LastSync settings.
            Write-PSFMessage -Level Host -String "InvokeDevDirectorySync.WhatIfSummary" -StringValues @($filteredCount, $localDevDir) -Tag "InvokeDevDirectorySync", "WhatIf"
        }

        #endregion Execute sync operation
    }

    end {
        Write-PSFMessage -Level Debug -String "InvokeDevDirectorySync.End" -Tag "InvokeDevDirectorySync", "End"
    }
}
