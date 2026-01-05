function Restore-DevDirectory {
    <#
    .SYNOPSIS
        Clones repositories from a repository list while preserving the folder layout.

    .DESCRIPTION
        Iterates over repository metadata entries, recreates the directory hierarchy relative to the
        target destination, and runs git clone for each entry. If the repository metadata includes
        user.name and user.email values, these are configured in the cloned repository's local .git/config.
        Existing directories can be skipped or replaced. The function supports WhatIf/Confirm semantics
        for safe execution.

    .PARAMETER InputObject
        Repository metadata objects, typically produced by Get-DevDirectory or Import-DevDirectoryList.

    .PARAMETER DestinationPath
        The root directory under which repositories will be restored. Defaults to the current location.

    .PARAMETER Force
        Overwrites existing directories by deleting them before cloning.

    .PARAMETER WhatIf
        Shows what would happen if the command runs. The command supports -WhatIf because it
        performs file system changes such as creating or deleting directories.

    .PARAMETER Confirm
        Prompts for confirmation before executing operations that change the system. The command
        supports -Confirm because it uses ShouldProcess for clone and deletion operations.

    .PARAMETER SkipExisting
        Skips repositories whose target directory already exists instead of throwing an error.

    .PARAMETER ShowGitOutput
        Displays git command output to the console. By default, git output is suppressed and only
        progress information is shown. Use this parameter for detailed git clone output or troubleshooting.

    .EXAMPLE
        PS C:\> Import-DevDirectoryList -Path "repos.json" | Restore-DevDirectory -DestinationPath "C:\Repos"

        Restores the repositories under C:\Repos using the layout described in repos.json.
        Shows progress bar and suppresses git output.

    .EXAMPLE
        PS C:\> Import-DevDirectoryList -Path "repos.json" | Restore-DevDirectory -DestinationPath "C:\Repos" -ShowGitOutput

        Restores the repositories and displays detailed git clone output to the console.

    .EXAMPLE
        PS C:\> Import-DevDirectoryList -Path "repos.csv" | Restore-DevDirectory -DestinationPath "D:\Projects" -SkipExisting

        Clones only repositories that don't already exist in D:\Projects, skipping any
        that are already present without error.

    .EXAMPLE
        PS C:\> Import-DevDirectoryList -Path "repos.json" | Where-Object RemoteUrl -like "*github.com*" | Restore-DevDirectory -DestinationPath "C:\GitHub"

        Restores only GitHub repositories to a specific location, filtering the list
        before restoration.

    .EXAMPLE
        PS C:\> Import-DevDirectoryList -Path "repos.xml" | Restore-DevDirectory -DestinationPath "C:\Repos" -Force -Verbose

        Restores repositories with verbose output, overwriting any existing directories.
        The -Force parameter removes existing directories before cloning.

    .EXAMPLE
        PS C:\> Import-DevDirectoryList -Path "repos.json" | Restore-DevDirectory -DestinationPath "C:\Repos" -WhatIf

        Shows what repositories would be cloned without actually performing the operation,
        useful for validating the restoration plan.

    .NOTES
        Version   : 1.4.4
        Author    : Andi Bellstedt, Copilot
        Date      : 2026-01-05
        Keywords  : Git, Restore, Clone

    .LINK
        https://github.com/AndiBellstedt/DevDirManager

    #>
    [CmdletBinding(
        SupportsShouldProcess = $true,
        ConfirmImpact = "Medium"
    )]
    [OutputType('DevDirManager.CloneResult')]
    param(
        [Parameter(Mandatory = $true, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true)]
        [ValidateNotNull()]
        [psobject[]]
        $InputObject,

        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [string]
        $DestinationPath = (Get-Location).ProviderPath,

        [Parameter()]
        [switch]
        $Force,

        [Parameter()]
        [switch]
        $SkipExisting,

        [Parameter()]
        [switch]
        $ShowGitOutput
    )

    begin {
        Write-PSFMessage -Level Debug -String 'RestoreDevDirectory.Start' -StringValues @($DestinationPath, $Force, $SkipExisting, $ShowGitOutput) -Tag "RestoreDevDirectory", "Start"

        # Retrieve the git executable path from configuration
        # This allows users to configure a custom git path via Set-PSFConfig
        $gitExecutable = Get-PSFConfigValue -FullName 'DevDirManager.Git.Executable'
        Write-PSFMessage -Level System -String 'RestoreDevDirectory.ConfigurationGitExe' -StringValues @($gitExecutable) -Tag "RestoreDevDirectory", "Configuration"

        ## Verify that the git executable is available before processing any repositories
        ## This early check prevents partial clone attempts when git is unavailable
        try {
            $gitCommand = Get-Command -Name $gitExecutable -ErrorAction Stop
            $resolvedGitPath = $gitCommand.Source
            Write-PSFMessage -Level Verbose -String 'RestoreDevDirectory.GitExeResolved' -StringValues @($resolvedGitPath) -Tag "RestoreDevDirectory", "Configuration"
        } catch {
            Write-PSFMessage -Level Error -String 'RestoreDevDirectory.GitExeNotFound' -StringValues @($gitExecutable) -Tag "RestoreDevDirectory", "Error"
            $messageValues = @($gitExecutable)
            $messageTemplate = Get-PSFLocalizedString -Module 'DevDirManager' -Name 'RestoreDevDirectory.GitExecutableMissing'
            $message = $messageTemplate -f $messageValues
            Stop-PSFFunction -String 'RestoreDevDirectory.GitExecutableMissing' -StringValues $messageValues -EnableException $true -Cmdlet $PSCmdlet -ErrorRecord $_
            throw $message
        }

        # Normalize the destination path to an absolute form with trailing backslash
        # This ensures consistent path operations and prevents relative path ambiguities
        $normalizedDestination = Resolve-NormalizedPath -Path $DestinationPath -EnsureTrailingBackslash
        Write-PSFMessage -Level Verbose -String 'RestoreDevDirectory.DestinationNormalized' -StringValues @($normalizedDestination.TrimEnd('\')) -Tag "RestoreDevDirectory", "Configuration"

        # Use the module-wide unsafe path pattern for security validation
        # This pattern rejects paths with: absolute paths (starts with \), drive letters (contains :), or path traversal (..)
        $invalidRelativePattern = $script:UnsafeRelativePathPattern

        $cloneActionTemplate = Get-PSFLocalizedString -Module 'DevDirManager' -Name 'RestoreDevDirectory.ActionClone'

        # Collect all repositories for progress tracking
        $repositoryQueue = [System.Collections.Generic.List[psobject]]::new()
    }

    process {
        # Collect repositories from pipeline
        foreach ($repository in $InputObject) {
            if ($repository) {
                $repositoryQueue.Add($repository)
            }
        }
    }

    end {
        # Get total count for progress tracking
        $totalCount = $repositoryQueue.Count
        $currentIndex = 0

        Write-PSFMessage -Level Verbose -String 'RestoreDevDirectory.ProcessingRepositories' -StringValues @($totalCount)

        # Process each repository entry
        foreach ($repository in $repositoryQueue) {
            # Skip null entries (can occur when pipeline sends empty objects)
            if (-not $repository) {
                continue
            }

            # Extract and validate the relative path and remote URL from the repository metadata
            $relativePath = [string]$repository.RelativePath
            $remoteUrl = [string]$repository.RemoteUrl

            # Skip repositories missing a remote URL (cannot clone without a source)
            if ([string]::IsNullOrWhiteSpace($remoteUrl)) {
                Write-PSFMessage -Level Warning -String 'RestoreDevDirectory.MissingRemoteUrl' -StringValues @($relativePath)
                $currentIndex++
                continue
            }

            # Skip repositories with inaccessible remotes (if IsRemoteAccessible property is set to false)
            if ($repository.PSObject.Properties.Match('IsRemoteAccessible') -and $repository.IsRemoteAccessible -eq $false) {
                Write-PSFMessage -Level Warning -String 'RestoreDevDirectory.InaccessibleRemoteSkipped' -StringValues @($relativePath, $remoteUrl)
                $currentIndex++
                continue
            }

            # Skip repositories whose SystemFilter does not match the current computer name.
            # Empty/null SystemFilter means "match all systems" (no filtering).
            $systemFilterValue = if ($repository.PSObject.Properties.Match('SystemFilter')) { $repository.SystemFilter } else { $null }
            if (-not (Test-DevDirectorySystemFilter -SystemFilter $systemFilterValue)) {
                Write-PSFMessage -Level Verbose -String 'RestoreDevDirectory.SystemFilterExcluded' -StringValues @($relativePath, $systemFilterValue, $env:COMPUTERNAME) -Tag "RestoreDevDirectory", "SystemFilter"
                $currentIndex++
                continue
            }

            # Skip repositories missing a relative path (cannot determine target directory)
            if ([string]::IsNullOrWhiteSpace($relativePath)) {
                Write-PSFMessage -Level Warning -String 'RestoreDevDirectory.MissingRelativePath' -StringValues @($remoteUrl)
                $currentIndex++
                continue
            }

            # Reject paths that could escape the destination root (security check)
            if ($invalidRelativePattern.IsMatch($relativePath)) {
                Write-PSFMessage -Level Warning -String 'RestoreDevDirectory.UnsafeRelativePath' -StringValues @($relativePath)
                $currentIndex++
                continue
            }

            # Construct the target path by combining destination root with the repository's relative path
            $targetPath = Join-Path -Path $normalizedDestination -ChildPath $relativePath
            $targetPath = [System.IO.Path]::GetFullPath($targetPath)

            # Verify that the resolved target path is still within the destination root (defense-in-depth check)
            if (-not $targetPath.StartsWith($normalizedDestination, [System.StringComparison]::OrdinalIgnoreCase)) {
                Write-PSFMessage -Level Warning -String 'RestoreDevDirectory.OutOfScopePath' -StringValues @($relativePath)
                $currentIndex++
                continue
            }

            # Ensure the parent directory exists before attempting to clone
            $targetParent = Split-Path -Path $targetPath
            if ([string]::IsNullOrEmpty($targetParent)) {
                $targetParent = $targetPath
            }

            if (-not (Test-Path -LiteralPath $targetParent -PathType Container)) {
                New-DirectoryIfNeeded -Path $targetParent
            }

            # Handle existing target directories according to SkipExisting/Force switch settings
            if (Test-Path -LiteralPath $targetPath -PathType Container) {
                if ($SkipExisting.IsPresent) {
                    Write-PSFMessage -Level Verbose -String 'RestoreDevDirectory.ExistingTargetVerbose' -StringValues @($targetPath)
                    $currentIndex++
                    continue
                }

                if (-not $Force.IsPresent) {
                    Write-PSFMessage -Level VeryVerbose -String 'RestoreDevDirectory.TargetExistsWarning' -StringValues @($targetPath)
                    $currentIndex++
                    continue
                }

                # Remove the existing directory tree to ensure a clean clone (when -Force is specified)
                Remove-Item -LiteralPath $targetPath -Recurse -Force
            }

            # Check for WhatIf/Confirm before performing the clone operation
            if (-not $PSCmdlet.ShouldProcess($targetPath, ($cloneActionTemplate -f @($remoteUrl)))) {
                $currentIndex++
                continue
            }

            # Update progress bar
            $currentIndex++
            $percentComplete = [int](($currentIndex / $totalCount) * 100)
            $progressParams = @{
                Activity         = "Cloning repositories"
                Status           = "Processing repository $currentIndex of $totalCount"
                CurrentOperation = "Cloning: $relativePath"
                PercentComplete  = $percentComplete
            }
            Write-Progress @progressParams

            Write-PSFMessage -Level Verbose -Message "Cloning repository $currentIndex/$totalCount`: $remoteUrl -> $targetPath"

            # Build the git clone command with --recurse-submodules to include nested repositories
            # Use -- separator to prevent URLs starting with - from being interpreted as options
            $argumentList = @("clone", "--recurse-submodules", "--", $remoteUrl, $targetPath)

            if ($ShowGitOutput) {
                # Show git output to console when explicitly requested
                $cloneProcess = Start-Process -FilePath $resolvedGitPath -ArgumentList $argumentList -NoNewWindow -Wait -PassThru
            } else {
                # Suppress git output by default (redirect to null)
                $cloneProcess = Start-Process -FilePath $resolvedGitPath -ArgumentList $argumentList -NoNewWindow -Wait -PassThru -RedirectStandardOutput ([System.IO.Path]::GetTempFileName()) -RedirectStandardError ([System.IO.Path]::GetTempFileName())
            }

            # Check the git clone exit code and log errors for failed clones
            if ($cloneProcess.ExitCode -ne 0) {
                Write-PSFMessage -Level Error -String 'RestoreDevDirectory.CloneFailed' -StringValues @($remoteUrl, $cloneProcess.ExitCode)
                continue
            }

            # Configure repository-local user.name and user.email if provided in metadata
            # This ensures that commits in the restored repository use the correct identity
            $userName = if ($repository.PSObject.Properties.Match("UserName")) { [string]$repository.UserName } else { $null }
            $userEmail = if ($repository.PSObject.Properties.Match("UserEmail")) { [string]$repository.UserEmail } else { $null }

            if (-not [string]::IsNullOrWhiteSpace($userName) -or -not [string]::IsNullOrWhiteSpace($userEmail)) {
                $gitConfigPath = Join-Path -Path $targetPath -ChildPath ".git\config"
                if (Test-Path -LiteralPath $gitConfigPath -PathType Leaf) {
                    # Use git config --local to set repository-specific user identity
                    if (-not [string]::IsNullOrWhiteSpace($userName)) {
                        $configArgs = @("config", "--local", "user.name", $userName)
                        if ($ShowGitOutput) {
                            $configProcess = Start-Process -FilePath $resolvedGitPath -ArgumentList $configArgs -WorkingDirectory $targetPath -NoNewWindow -Wait -PassThru
                        } else {
                            $configProcess = Start-Process -FilePath $resolvedGitPath -ArgumentList $configArgs -WorkingDirectory $targetPath -NoNewWindow -Wait -PassThru -RedirectStandardOutput ([System.IO.Path]::GetTempFileName()) -RedirectStandardError ([System.IO.Path]::GetTempFileName())
                        }
                        if ($configProcess.ExitCode -ne 0) {
                            Write-PSFMessage -Level Error -String 'RestoreDevDirectory.ConfigFailed' -StringValues @("user.name", $userName, $targetPath, $configProcess.ExitCode)
                        }
                    }
                    if (-not [string]::IsNullOrWhiteSpace($userEmail)) {
                        $configArgs = @("config", "--local", "user.email", $userEmail)
                        if ($ShowGitOutput) {
                            $configProcess = Start-Process -FilePath $resolvedGitPath -ArgumentList $configArgs -WorkingDirectory $targetPath -NoNewWindow -Wait -PassThru
                        } else {
                            $configProcess = Start-Process -FilePath $resolvedGitPath -ArgumentList $configArgs -WorkingDirectory $targetPath -NoNewWindow -Wait -PassThru -RedirectStandardOutput ([System.IO.Path]::GetTempFileName()) -RedirectStandardError ([System.IO.Path]::GetTempFileName())
                        }
                        if ($configProcess.ExitCode -ne 0) {
                            Write-PSFMessage -Level Error -String 'RestoreDevDirectory.ConfigFailed' -StringValues @("user.email", $userEmail, $targetPath, $configProcess.ExitCode)
                        }
                    }
                }
            }

            # Emit a summary object to the pipeline so callers can audit what was cloned
            [pscustomobject]@{
                PSTypeName = 'DevDirManager.CloneResult'
                RemoteUrl  = $remoteUrl
                TargetPath = $targetPath
                Status     = "Cloned"
            }
        }

        # Complete the progress bar
        Write-Progress -Activity "Cloning repositories" -Completed

        Write-PSFMessage -Level Verbose -String 'RestoreDevDirectory.Complete' -StringValues @($totalCount) -Tag "RestoreDevDirectory", "Complete"
    }
}
