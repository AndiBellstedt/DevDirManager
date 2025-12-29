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
        Version   : 1.1.0
        Author    : Andi Bellstedt, Copilot
        Date      : 2025-12-29
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
        $taskName = Get-PSFConfigValue -FullName "DevDirManager.Internal.ScheduledTaskName"

        Write-PSFMessage -Level Debug -String "UnregisterDevDirectoryScheduledSync.Start" -StringValues @($taskName) -Tag "UnregisterDevDirectoryScheduledSync", "Start"
    }

    process {
        #region -- Check if task exists

        $existingTask = Get-ScheduledTask -TaskName $taskName -ErrorAction SilentlyContinue

        if (-not $existingTask) {
            Write-PSFMessage -Level Warning -String "UnregisterDevDirectoryScheduledSync.NotFound" -StringValues @($taskName) -Tag "UnregisterDevDirectoryScheduledSync", "NotFound"

            # Even if task doesn't exist, ensure AutoSyncEnabled is false for consistency.
            Set-PSFConfig -Module "DevDirManager" -Name "System.AutoSyncEnabled" -Value $false -DisableHandler
            return
        }

        #endregion Check if task exists

        #region -- Remove the scheduled task

        if ($PSCmdlet.ShouldProcess($taskName, "Remove scheduled task")) {
            Unregister-ScheduledTask -TaskName $taskName -Confirm:$false

            Write-PSFMessage -Level Host -String "UnregisterDevDirectoryScheduledSync.Removed" -StringValues @($taskName) -Tag "UnregisterDevDirectoryScheduledSync", "Removed"

            # Update AutoSyncEnabled to false in PSFConfig (disable handler to prevent recursion).
            Set-PSFConfig -Module "DevDirManager" -Name "System.AutoSyncEnabled" -Value $false -DisableHandler

            Write-PSFMessage -Level Important -String "UnregisterDevDirectoryScheduledSync.AutoSyncDisabled" -Tag "UnregisterDevDirectoryScheduledSync", "AutoSync"
        }

        #endregion Remove the scheduled task
    }

    end {
        Write-PSFMessage -Level Debug -String "UnregisterDevDirectoryScheduledSync.Complete" -Tag "UnregisterDevDirectoryScheduledSync", "Complete"
    }
}
