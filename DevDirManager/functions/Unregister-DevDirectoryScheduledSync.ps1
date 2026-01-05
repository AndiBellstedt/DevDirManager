function Unregister-DevDirectoryScheduledSync {
    <#
    .SYNOPSIS
        Removes the scheduled task for automated repository synchronization.

    .DESCRIPTION
        Removes the Windows scheduled task that was created by Register-DevDirectoryScheduledSync.
        This stops automated synchronization of repositories.

        The task name is automatically determined based on the current user and
        PowerShell version to match the task created by Register-DevDirectoryScheduledSync.

        Also sets AutoSyncEnabled to false in the system configuration to maintain
        consistency between the scheduled task state and configuration.

    .PARAMETER WhatIf
        Shows what would happen if the cmdlet runs. The cmdlet is not run.

    .PARAMETER Confirm
        Prompts you for confirmation before running the cmdlet.

    .EXAMPLE
        PS C:\> Unregister-DevDirectoryScheduledSync

        Removes the DevDirManager scheduled sync task and disables AutoSync in settings.

    .EXAMPLE
        PS C:\> Unregister-DevDirectoryScheduledSync -WhatIf

        Shows what would be removed without actually removing the task.

    .NOTES
        Version   : 1.3.0
        Author    : Andi Bellstedt, Copilot
        Date      : 2026-01-03
        Keywords  : ScheduledTask, Sync, Automation

    .LINK
        https://github.com/AndiBellstedt/DevDirManager

    #>
    [CmdletBinding(
        SupportsShouldProcess = $true,
        ConfirmImpact = "Medium"
    )]
    [OutputType([void])]
    param()

    begin {
        # Get the task name from PSFConfig (set during module import).
        $taskName = Get-PSFConfigValue -FullName "DevDirManager.ScheduledTaskName"

        Write-PSFMessage -Level Debug -String "UnregisterDevDirectoryScheduledSync.Start" -StringValues @($taskName) -Tag "UnregisterDevDirectoryScheduledSync", "Start"
    }

    process {
        #region -- Check if task exists

        $existingTask = Get-ScheduledTask -TaskPath "\" -TaskName $taskName -ErrorAction SilentlyContinue

        if (-not $existingTask) {
            Stop-PSFFunction -Message (Get-PSFLocalizedString -Module "DevDirManager" -Name "UnregisterDevDirectoryScheduledSync.NotFound") -StringValues @($taskName) -Category ObjectNotFound -Tag "UnregisterDevDirectoryScheduledSync", "NotFound"
            return
        }

        #endregion Check if task exists

        #region -- Remove the scheduled task

        # Get localized ShouldProcess text.
        $shouldProcessTarget = Get-PSFLocalizedString -Module "DevDirManager" -Name "UnregisterDevDirectoryScheduledSync.ShouldProcess.Target"
        $shouldProcessAction = (Get-PSFLocalizedString -Module "DevDirManager" -Name "UnregisterDevDirectoryScheduledSync.ShouldProcess.Action") -f $taskName

        if ($PSCmdlet.ShouldProcess($shouldProcessTarget, $shouldProcessAction)) {
            try {
                Unregister-ScheduledTask -TaskPath "\" -TaskName $taskName -Confirm:$false -ErrorAction Stop
            } catch {
                Stop-PSFFunction -Message (Get-PSFLocalizedString -Module "DevDirManager" -Name "UnregisterDevDirectoryScheduledSync.UnregisterFailed") -StringValues @($taskName) -EnableException $true -ErrorRecord $_ -Tag "UnregisterDevDirectoryScheduledSync", "Error"
                return
            }

            Write-PSFMessage -Level Host -String "UnregisterDevDirectoryScheduledSync.Removed" -StringValues @($taskName) -Tag "UnregisterDevDirectoryScheduledSync", "Removed", "AutoSync"

            # Update AutoSyncEnabled setting to false directly in config file.
            # Note: We write directly to the config file instead of calling Set-DevDirectorySetting
            # to avoid infinite recursion (Set-DevDirectorySetting calls this function when AutoSyncEnabled changes).
            $settingsPath = Get-PSFConfigValue -FullName "DevDirManager.SettingsPath"
            try {
                $jsonContent = Get-Content -Path $settingsPath -Raw -Encoding UTF8
                $currentSettings = $jsonContent | ConvertFrom-Json
                $currentSettings.AutoSyncEnabled = $false
                $updatedJson = $currentSettings | ConvertTo-Json -Depth 3
                Write-ConfigFileWithRetry -Path $settingsPath -Content $updatedJson
                Write-PSFMessage -Level Verbose -String "UnregisterDevDirectoryScheduledSync.AutoSyncDisabled" -Tag "UnregisterDevDirectoryScheduledSync", "Settings"
            } catch {
                Write-PSFMessage -Level Warning -Message "Failed to update AutoSyncEnabled in config file: $($_.Exception.Message)" -Tag "UnregisterDevDirectoryScheduledSync", "Warning"
            }
        }

        #endregion Remove the scheduled task
    }

    end {
        Write-PSFMessage -Level Debug -String "UnregisterDevDirectoryScheduledSync.Complete" -Tag "UnregisterDevDirectoryScheduledSync", "Complete"
    }
}
