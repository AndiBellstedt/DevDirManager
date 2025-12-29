function Register-DevDirectoryScheduledSync {
    <#
    .SYNOPSIS
        Registers a scheduled task for automated repository synchronization.

    .DESCRIPTION
        Creates a Windows scheduled task that runs Invoke-DevDirectorySync at the
        configured interval using the system settings. Requires the system settings
        to be configured via Set-DevDirectorySetting first.

        The scheduled task runs under the current user's context and triggers
        at the specified interval. Optionally, the task can also be configured
        to run at user logon.

        This function requires administrative privileges to create scheduled tasks.

    .PARAMETER TaskName
        Name for the scheduled task. Defaults to "DevDirManager-AutoSync".

    .PARAMETER RunAtLogon
        Also triggers the sync task at user logon in addition to the interval trigger.

    .PARAMETER Force
        Overwrites an existing task with the same name without prompting.

    .PARAMETER WhatIf
        Shows what would happen if the cmdlet runs. The cmdlet is not run.

    .PARAMETER Confirm
        Prompts you for confirmation before running the cmdlet.

    .EXAMPLE
        PS C:\> Register-DevDirectoryScheduledSync

        Creates a scheduled task using the configured sync interval from system settings.

    .EXAMPLE
        PS C:\> Register-DevDirectoryScheduledSync -RunAtLogon

        Creates a scheduled task that runs at the configured interval and also at user logon.

    .EXAMPLE
        PS C:\> Register-DevDirectoryScheduledSync -TaskName "MyRepoSync" -Force

        Creates or updates a scheduled task with custom name, overwriting if it exists.

    .EXAMPLE
        PS C:\> Register-DevDirectoryScheduledSync -WhatIf

        Shows what scheduled task would be created without actually creating it.

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
    [OutputType([Microsoft.Management.Infrastructure.CimInstance])]
    param(
        [Parameter(Position = 0)]
        [ValidateNotNullOrEmpty()]
        [string]
        $TaskName = "DevDirManager-AutoSync",

        [Parameter()]
        [switch]
        $RunAtLogon,

        [Parameter()]
        [switch]
        $Force
    )

    begin {
        Write-PSFMessage -Level Debug -String "RegisterDevDirectoryScheduledSync.Start" -StringValues @($TaskName) -Tag "RegisterDevDirectoryScheduledSync", "Start"

        #region -- Validate system configuration

        $settings = Get-DevDirectorySetting

        if ([string]::IsNullOrWhiteSpace($settings.RepositoryListPath)) {
            Stop-PSFFunction -Message (Get-PSFLocalizedString -Module "DevDirManager" -Name "RegisterDevDirectoryScheduledSync.NotConfigured.RepositoryListPath") -EnableException $true -Category InvalidOperation -Tag "RegisterDevDirectoryScheduledSync", "Configuration"
            return
        }

        if ([string]::IsNullOrWhiteSpace($settings.LocalDevDirectory)) {
            Stop-PSFFunction -Message (Get-PSFLocalizedString -Module "DevDirManager" -Name "RegisterDevDirectoryScheduledSync.NotConfigured.LocalDevDirectory") -EnableException $true -Category InvalidOperation -Tag "RegisterDevDirectoryScheduledSync", "Configuration"
            return
        }

        #endregion Validate system configuration

        #region -- Check for existing task

        $existingTask = Get-ScheduledTask -TaskName $TaskName -ErrorAction SilentlyContinue
        if ($existingTask -and -not $Force) {
            Stop-PSFFunction -Message (Get-PSFLocalizedString -Module "DevDirManager" -Name "RegisterDevDirectoryScheduledSync.Exists") -StringValues @($TaskName) -EnableException $true -Category ResourceExists -Tag "RegisterDevDirectoryScheduledSync", "Exists"
            return
        }

        #endregion Check for existing task
    }

    process {
        if (Test-PSFFunctionInterrupt) { return }

        #region -- Build scheduled task components

        # Determine the PowerShell executable path.
        # Use pwsh.exe for PowerShell 7+ and powershell.exe for Windows PowerShell.
        if ($PSVersionTable.PSVersion.Major -ge 6) {
            $psExecutable = "pwsh.exe"
        } else {
            $psExecutable = "powershell.exe"
        }

        # Build the command to execute.
        $syncCommand = "Import-Module DevDirManager -Force; Invoke-DevDirectorySync"
        $arguments = "-NoProfile -NonInteractive -WindowStyle Hidden -ExecutionPolicy Bypass -Command `"$($syncCommand)`""

        # Create the action.
        $action = New-ScheduledTaskAction -Execute $psExecutable -Argument $arguments

        # Create the trigger(s).
        $triggerList = @()

        # Interval-based trigger.
        $intervalMinutes = $settings.SyncIntervalMinutes
        if ($intervalMinutes -gt 0) {
            $intervalTrigger = New-ScheduledTaskTrigger -Once -At (Get-Date) -RepetitionInterval (New-TimeSpan -Minutes $intervalMinutes)
            $triggerList += $intervalTrigger
        }

        # Logon trigger if requested.
        if ($RunAtLogon) {
            $logonTrigger = New-ScheduledTaskTrigger -AtLogOn -User $env:USERNAME
            $triggerList += $logonTrigger
        }

        # Create the principal (run as current user).
        $principal = New-ScheduledTaskPrincipal -UserId $env:USERNAME -LogonType Interactive -RunLevel Limited

        # Create task settings.
        $taskSettings = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries -StartWhenAvailable -ExecutionTimeLimit (New-TimeSpan -Hours 1)

        #endregion Build scheduled task components

        #region -- Register the scheduled task

        $taskDescription = "Automatically synchronizes Git repositories using DevDirManager. Syncs from '$($settings.RepositoryListPath)' to '$($settings.LocalDevDirectory)' every $($intervalMinutes) minutes."

        if ($PSCmdlet.ShouldProcess($TaskName, "Register scheduled task")) {
            # Remove existing task if Force is specified.
            if ($existingTask -and $Force) {
                Write-PSFMessage -Level Verbose -String "RegisterDevDirectoryScheduledSync.RemovingExisting" -StringValues @($TaskName) -Tag "RegisterDevDirectoryScheduledSync", "Remove"
                Unregister-ScheduledTask -TaskName $TaskName -Confirm:$false
            }

            # Register the new task.
            $task = Register-ScheduledTask -TaskName $TaskName -Action $action -Trigger $triggerList -Principal $principal -Settings $taskSettings -Description $taskDescription

            Write-PSFMessage -Level Host -String "RegisterDevDirectoryScheduledSync.Created" -StringValues @($TaskName, $intervalMinutes) -Tag "RegisterDevDirectoryScheduledSync", "Created"

            # Return the created task.
            $task
        }

        #endregion Register the scheduled task
    }

    end {
        Write-PSFMessage -Level Debug -String "RegisterDevDirectoryScheduledSync.Complete" -Tag "RegisterDevDirectoryScheduledSync", "Complete"
    }
}
