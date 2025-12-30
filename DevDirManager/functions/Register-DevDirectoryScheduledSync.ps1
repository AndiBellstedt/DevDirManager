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

        The task name is automatically generated to be unique per user and
        PowerShell version to avoid conflicts in multi-user environments.

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
        PS C:\> Register-DevDirectoryScheduledSync -Force

        Creates or updates the scheduled task, overwriting if it exists.

    .EXAMPLE
        PS C:\> Register-DevDirectoryScheduledSync -WhatIf

        Shows what scheduled task would be created without actually creating it.

    .NOTES
        Version   : 1.2.0
        Author    : Andi Bellstedt, Copilot
        Date      : 2025-12-30
        Keywords  : ScheduledTask, Sync, Automation

        Security Note: The -ExecutionPolicy parameter is intentionally omitted from
        the PowerShell arguments. This is by design for security reasons - the
        execution policy should be configured at the system or user level, not
        bypassed by individual scripts.

    .LINK
        https://github.com/AndiBellstedt/DevDirManager

    #>
    [CmdletBinding(
        SupportsShouldProcess = $true,
        ConfirmImpact = "Medium"
    )]
    [OutputType([Microsoft.Management.Infrastructure.CimInstance])]
    param(
        [Parameter()]
        [switch]
        $RunAtLogon,

        [Parameter()]
        [switch]
        $Force
    )

    begin {
        # Get the task name from PSFConfig (set during module import).
        $taskName = Get-PSFConfigValue -FullName "DevDirManager.ScheduledTaskName"

        Write-PSFMessage -Level Debug -String "RegisterDevDirectoryScheduledSync.Start" -StringValues @($taskName) -Tag "RegisterDevDirectoryScheduledSync", "Start"

        #region -- Validate system configuration using Get-DevDirectorySetting

        $repoListPath = Get-DevDirectorySetting -Name RepositoryListPath
        $localDevDir = Get-DevDirectorySetting -Name LocalDevDirectory
        $syncInterval = Get-DevDirectorySetting -Name SyncIntervalMinutes

        if ([string]::IsNullOrWhiteSpace($repoListPath)) {
            Stop-PSFFunction -Message (Get-PSFLocalizedString -Module "DevDirManager" -Name "RegisterDevDirectoryScheduledSync.NotConfigured.RepositoryListPath") -EnableException $true -Category InvalidOperation -Tag "RegisterDevDirectoryScheduledSync", "Configuration"
            return
        }

        if ([string]::IsNullOrWhiteSpace($localDevDir)) {
            Stop-PSFFunction -Message (Get-PSFLocalizedString -Module "DevDirManager" -Name "RegisterDevDirectoryScheduledSync.NotConfigured.LocalDevDirectory") -EnableException $true -Category InvalidOperation -Tag "RegisterDevDirectoryScheduledSync", "Configuration"
            return
        }

        #endregion Validate system configuration

        #region -- Check for existing task

        $existingTask = Get-ScheduledTask -TaskPath "\" -TaskName $taskName -ErrorAction SilentlyContinue
        if ($existingTask -and -not $Force) {
            Stop-PSFFunction -Message (Get-PSFLocalizedString -Module "DevDirManager" -Name "RegisterDevDirectoryScheduledSync.Exists") -StringValues @($taskName) -EnableException $true -Category ResourceExists -Tag "RegisterDevDirectoryScheduledSync", "Exists"
            return
        }

        #endregion Check for existing task
    }

    process {
        if (Test-PSFFunctionInterrupt) { return }

        #region -- Build scheduled task components

        # Get the PowerShell executable from the environment (full path).
        $psExecutable = [Environment]::ProcessPath
        if ([string]::IsNullOrWhiteSpace($psExecutable)) {
            # Fallback for older PowerShell versions that don't have ProcessPath.
            if ($PSVersionTable.PSVersion.Major -ge 6) {
                $psExecutable = (Get-Process -Id $PID).Path
            } else {
                $psExecutable = [Environment]::CommandLine
                if ([string]::IsNullOrWhiteSpace($psExecutable)) {
                    $psExecutable = Join-Path -Path $PSHOME -ChildPath "powershell.exe"
                }
            }
        }

        # Build the command to execute.
        # Note: ExecutionPolicy is intentionally omitted for security reasons.
        # The execution policy should be configured at the system or user level.
        $syncCommand = "Import-Module DevDirManager -Force; Invoke-DevDirectorySyncSchedule"
        $arguments = "-NoProfile -NonInteractive -WindowStyle Hidden -Command `"$($syncCommand)`""

        # Create the action.
        $action = New-ScheduledTaskAction -Execute $psExecutable -Argument $arguments

        # Create the trigger(s).
        $triggerList = @()

        # Interval-based trigger.
        if ($syncInterval -gt 0) {
            $intervalTrigger = New-ScheduledTaskTrigger -Once -At (Get-Date) -RepetitionInterval (New-TimeSpan -Minutes $syncInterval)
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

        # Get localized task description.
        $taskDescription = Get-PSFLocalizedString -Module "DevDirManager" -Name "RegisterDevDirectoryScheduledSync.TaskDescription"

        # Get localized ShouldProcess text.
        $shouldProcessTarget = Get-PSFLocalizedString -Module "DevDirManager" -Name "RegisterDevDirectoryScheduledSync.ShouldProcess.Target"
        $shouldProcessAction = (Get-PSFLocalizedString -Module "DevDirManager" -Name "RegisterDevDirectoryScheduledSync.ShouldProcess.Action") -f $taskName, $syncInterval

        if ($PSCmdlet.ShouldProcess($shouldProcessTarget, $shouldProcessAction)) {
            # Remove existing task if Force is specified.
            if ($existingTask -and $Force) {
                Write-PSFMessage -Level Verbose -String "RegisterDevDirectoryScheduledSync.RemovingExisting" -StringValues @($taskName) -Tag "RegisterDevDirectoryScheduledSync", "Remove"
                try {
                    Unregister-ScheduledTask -TaskPath "\" -TaskName $taskName -Confirm:$false -ErrorAction Stop
                } catch {
                    Stop-PSFFunction -Message (Get-PSFLocalizedString -Module "DevDirManager" -Name "RegisterDevDirectoryScheduledSync.UnregisterFailed") -StringValues @($taskName) -EnableException $true -ErrorRecord $_ -Tag "RegisterDevDirectoryScheduledSync", "Error"
                    return
                }
            }

            # Register the new task in the root task path.
            try {
                $task = Register-ScheduledTask -TaskPath "\" -TaskName $taskName -Action $action -Trigger $triggerList -Principal $principal -Settings $taskSettings -Description $taskDescription -ErrorAction Stop
            } catch {
                Stop-PSFFunction -Message (Get-PSFLocalizedString -Module "DevDirManager" -Name "RegisterDevDirectoryScheduledSync.RegisterFailed") -StringValues @($taskName) -EnableException $true -ErrorRecord $_ -Tag "RegisterDevDirectoryScheduledSync", "Error"
                return
            }

            # Verify task was created.
            if (-not $task) {
                Stop-PSFFunction -Message (Get-PSFLocalizedString -Module "DevDirManager" -Name "RegisterDevDirectoryScheduledSync.TaskNotReturned") -StringValues @($taskName) -EnableException $true -Category InvalidResult -Tag "RegisterDevDirectoryScheduledSync", "Error"
                return
            }

            Write-PSFMessage -Level Host -String "RegisterDevDirectoryScheduledSync.Created" -StringValues @($taskName, $syncInterval) -Tag "RegisterDevDirectoryScheduledSync", "Created", "AutoSync"

            # Update AutoSyncEnabled setting to true.
            Set-DevDirectorySetting -AutoSyncEnabled $true
            Write-PSFMessage -Level Verbose -String "RegisterDevDirectoryScheduledSync.AutoSyncEnabled" -Tag "RegisterDevDirectoryScheduledSync", "Settings"

            # Return the created task.
            $task
        }

        #endregion Register the scheduled task
    }

    end {
        Write-PSFMessage -Level Debug -String "RegisterDevDirectoryScheduledSync.Complete" -Tag "RegisterDevDirectoryScheduledSync", "Complete"
    }
}
