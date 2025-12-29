function Unregister-DevDirectoryScheduledSync {
    <#
    .SYNOPSIS
        Removes the scheduled task for automated repository synchronization.

    .DESCRIPTION
        Removes the Windows scheduled task that was created by Register-DevDirectoryScheduledSync.
        This stops automated synchronization of repositories.

    .PARAMETER TaskName
        Name of the scheduled task to remove. Defaults to "DevDirManager-AutoSync".

    .PARAMETER WhatIf
        Shows what would happen if the cmdlet runs. The cmdlet is not run.

    .PARAMETER Confirm
        Prompts you for confirmation before running the cmdlet.

    .EXAMPLE
        PS C:\> Unregister-DevDirectoryScheduledSync

        Removes the default "DevDirManager-AutoSync" scheduled task.

    .EXAMPLE
        PS C:\> Unregister-DevDirectoryScheduledSync -TaskName "MyRepoSync"

        Removes a scheduled task with a custom name.

    .EXAMPLE
        PS C:\> Unregister-DevDirectoryScheduledSync -WhatIf

        Shows what would be removed without actually removing the task.

    .NOTES
        Version   : 1.0.0
        Author    : Andi Bellstedt, Copilot
        Date      : 2025-12-28
        Keywords  : ScheduledTask, Sync, Automation

    .LINK
        https://github.com/AndiBellstedt/DevDirManager

    #>
    [CmdletBinding(
        SupportsShouldProcess = $true,
        ConfirmImpact = "Medium"
    )]
    [OutputType([void])]
    param(
        [Parameter(Position = 0, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true)]
        [ValidateNotNullOrEmpty()]
        [Alias("Name")]
        [string]
        $TaskName = "DevDirManager-AutoSync"
    )

    begin {
        Write-PSFMessage -Level Debug -String "UnregisterDevDirectoryScheduledSync.Start" -StringValues @($TaskName) -Tag "UnregisterDevDirectoryScheduledSync", "Start"
    }

    process {
        #region -- Check if task exists

        $existingTask = Get-ScheduledTask -TaskName $TaskName -ErrorAction SilentlyContinue

        if (-not $existingTask) {
            Write-PSFMessage -Level Warning -String "UnregisterDevDirectoryScheduledSync.NotFound" -StringValues @($TaskName) -Tag "UnregisterDevDirectoryScheduledSync", "NotFound"
            return
        }

        #endregion Check if task exists

        #region -- Remove the scheduled task

        if ($PSCmdlet.ShouldProcess($TaskName, "Remove scheduled task")) {
            Unregister-ScheduledTask -TaskName $TaskName -Confirm:$false

            Write-PSFMessage -Level Host -String "UnregisterDevDirectoryScheduledSync.Removed" -StringValues @($TaskName) -Tag "UnregisterDevDirectoryScheduledSync", "Removed"
        }

        #endregion Remove the scheduled task
    }

    end {
        Write-PSFMessage -Level Debug -String "UnregisterDevDirectoryScheduledSync.Complete" -Tag "UnregisterDevDirectoryScheduledSync", "Complete"
    }
}
