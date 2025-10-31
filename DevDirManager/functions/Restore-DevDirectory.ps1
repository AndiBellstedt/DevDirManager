﻿function Restore-DevDirectory {
    <#
    .SYNOPSIS
        Clones repositories from a repository list while preserving the folder layout.

    .DESCRIPTION
        Iterates over repository metadata entries, recreates the directory hierarchy relative to the
        target destination, and runs git clone for each entry. Existing directories can be skipped or
        replaced. The function supports WhatIf/Confirm semantics for safe execution.

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

    .EXAMPLE
        PS C:\> Import-DevDirectoryList -Path "repos.json" | Restore-DevDirectory -DestinationPath "C:\Repos"

        Restores the repositories under C:\Repos using the layout described in repos.json.

    .NOTES
        Version   : 1.1.1
        Author    : Andi Bellstedt, Copilot
        Date      : 2025-10-31
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
        $SkipExisting
    )

    begin {
        # Retrieve the git executable path from configuration
        # This allows users to configure a custom git path via Set-PSFConfig
        $gitExecutable = Get-PSFConfigValue -FullName 'DevDirManager.Git.Executable'

        ## Verify that the git executable is available before processing any repositories
        ## This early check prevents partial clone attempts when git is unavailable
        try {
            $gitCommand = Get-Command -Name $gitExecutable -ErrorAction Stop
            $resolvedGitPath = $gitCommand.Source
        } catch {
            $messageValues = @($gitExecutable)
            $messageTemplate = Get-PSFLocalizedString -Module 'DevDirManager' -Name 'RestoreDevDirectory.GitExecutableMissing'
            $message = $messageTemplate -f $messageValues
            Stop-PSFFunction -String 'RestoreDevDirectory.GitExecutableMissing' -StringValues $messageValues -EnableException $true -Cmdlet $PSCmdlet -ErrorRecord $_
            throw $message
        }

        # Normalize the destination path to an absolute form with trailing backslash
        # This ensures consistent path operations and prevents relative path ambiguities
        $destinationRoot = Resolve-Path -LiteralPath $DestinationPath -ErrorAction Stop
        $normalizedDestination = [System.IO.Path]::GetFullPath($destinationRoot.ProviderPath)
        if (-not $normalizedDestination.EndsWith("\", [System.StringComparison]::Ordinal)) {
            $normalizedDestination = "$($normalizedDestination)\"
        }

        # Define regex pattern to reject unsafe relative paths that could escape the destination
        # Matches: absolute paths (starts with \), drive letters (contains :), or path traversal (..)
        $invalidRelativePattern = [regex]::new("(^\\|:|\.\.)")

        $cloneActionTemplate = Get-PSFLocalizedString -Module 'DevDirManager' -Name 'RestoreDevDirectory.ActionClone'
    }

    process {
        # Process each repository entry from the pipeline or InputObject array
        # Each iteration attempts to clone one repository to its target path
        foreach ($repository in $InputObject) {
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
                continue
            }

            # Skip repositories missing a relative path (cannot determine target directory)
            if ([string]::IsNullOrWhiteSpace($relativePath)) {
                Write-PSFMessage -Level Warning -String 'RestoreDevDirectory.MissingRelativePath' -StringValues @($remoteUrl)
                continue
            }

            # Reject paths that could escape the destination root (security check)
            if ($invalidRelativePattern.IsMatch($relativePath)) {
                Write-PSFMessage -Level Warning -String 'RestoreDevDirectory.UnsafeRelativePath' -StringValues @($relativePath)
                continue
            }

            # Construct the target path by combining destination root with the repository's relative path
            $targetPath = Join-Path -Path $normalizedDestination -ChildPath $relativePath
            $targetPath = [System.IO.Path]::GetFullPath($targetPath)

            # Verify that the resolved target path is still within the destination root (defense-in-depth check)
            if (-not $targetPath.StartsWith($normalizedDestination, [System.StringComparison]::OrdinalIgnoreCase)) {
                Write-PSFMessage -Level Warning -String 'RestoreDevDirectory.OutOfScopePath' -StringValues @($relativePath)
                continue
            }

            # Ensure the parent directory exists before attempting to clone
            $targetParent = Split-Path -Path $targetPath
            if ([string]::IsNullOrEmpty($targetParent)) {
                $targetParent = $targetPath
            }

            if (-not (Test-Path -LiteralPath $targetParent -PathType Container)) {
                New-Item -ItemType Directory -Path $targetParent -Force | Out-Null
            }

            # Handle existing target directories according to SkipExisting/Force switch settings
            if (Test-Path -LiteralPath $targetPath -PathType Container) {
                if ($SkipExisting.IsPresent) {
                    Write-PSFMessage -Level Verbose -String 'RestoreDevDirectory.ExistingTargetVerbose' -StringValues @($targetPath)
                    continue
                }

                if (-not $Force.IsPresent) {
                    Write-PSFMessage -Level Warning -String 'RestoreDevDirectory.TargetExistsWarning' -StringValues @($targetPath)
                    continue
                }

                # Remove the existing directory tree to ensure a clean clone (when -Force is specified)
                Remove-Item -LiteralPath $targetPath -Recurse -Force
            }

            # Check for WhatIf/Confirm before performing the clone operation
            if (-not $PSCmdlet.ShouldProcess($targetPath, ($cloneActionTemplate -f @($remoteUrl)))) {
                continue
            }

            # Build the git clone command with --recurse-submodules to include nested repositories
            # Use -- separator to prevent URLs starting with - from being interpreted as options
            $argumentList = @("clone", "--recurse-submodules", "--", $remoteUrl, $targetPath)
            $cloneProcess = Start-Process -FilePath $resolvedGitPath -ArgumentList $argumentList -NoNewWindow -Wait -PassThru

            # Check the git clone exit code and log errors for failed clones
            if ($cloneProcess.ExitCode -ne 0) {
                Write-PSFMessage -Level Error -String 'RestoreDevDirectory.CloneFailed' -StringValues @($remoteUrl, $cloneProcess.ExitCode)
                continue
            }

            # Emit a summary object to the pipeline so callers can audit what was cloned
            [pscustomobject]@{
                PSTypeName = 'DevDirManager.CloneResult'
                RemoteUrl  = $remoteUrl
                TargetPath = $targetPath
                Status     = "Cloned"
            }
        }
    }
}
