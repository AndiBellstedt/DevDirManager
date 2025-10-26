function Restore-DevDirectory {
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

    .PARAMETER GitExecutable
        The git executable to invoke. Defaults to "git".

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
        Version   : 1.0.0
        Author    : Andi Bellstedt, Copilot
        Date      : 2025-10-26
        Keywords  : Git, Restore, Clone

    .LINK
        https://github.com/AndiBellstedt/DevDirManager

    #>
    [CmdletBinding(
        SupportsShouldProcess = $true,
        ConfirmImpact = "Medium"
    )]
    [OutputType([psobject])]
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
        [ValidateNotNullOrEmpty()]
        [string]
        $GitExecutable = "git",

        [Parameter()]
        [switch]
        $Force,

        [Parameter()]
        [switch]
        $SkipExisting
    )

    begin {
        try {
            $gitCommand = Get-Command -Name $GitExecutable -ErrorAction Stop
            $resolvedGitPath = $gitCommand.Source
        } catch {
            throw "Unable to locate the git executable '$GitExecutable'. Ensure Git is installed and available in PATH."
        }

        $destinationRoot = Resolve-Path -LiteralPath $DestinationPath -ErrorAction Stop
        $normalizedDestination = [System.IO.Path]::GetFullPath($destinationRoot.ProviderPath)
        if (-not $normalizedDestination.EndsWith("\", [System.StringComparison]::Ordinal)) {
            $normalizedDestination = "$($normalizedDestination)\"
        }

        # Matches unsafe relative paths: starts with backslash, contains colon, or ".." (path traversal)
        $invalidRelativePattern = [regex]::new("(^\\|:|\.\.)")
    }

    process {
        foreach ($repository in $InputObject) {
            if (-not $repository) {
                continue
            }

            $relativePath = [string]$repository.RelativePath
            $remoteUrl = [string]$repository.RemoteUrl

            if ([string]::IsNullOrWhiteSpace($remoteUrl)) {
                Write-PSFMessage -Level Warning -Message "Skipping repository with missing RemoteUrl: $($relativePath)."
                continue
            }

            if ([string]::IsNullOrWhiteSpace($relativePath)) {
                Write-PSFMessage -Level Warning -Message "Skipping repository with missing RelativePath for remote $($remoteUrl)."
                continue
            }

            if ($invalidRelativePattern.IsMatch($relativePath)) {
                Write-PSFMessage -Level Warning -Message "Skipping repository with unsafe relative path '$relativePath'."
                continue
            }

            $targetPath = Join-Path -Path $normalizedDestination -ChildPath $relativePath
            $targetPath = [System.IO.Path]::GetFullPath($targetPath)

            if (-not $targetPath.StartsWith($normalizedDestination, [System.StringComparison]::OrdinalIgnoreCase)) {
                Write-PSFMessage -Level Warning -Message "Skipping repository with out-of-scope path '$relativePath'."
                continue
            }

            $targetParent = Split-Path -Path $targetPath
            if ([string]::IsNullOrEmpty($targetParent)) {
                $targetParent = $targetPath
            }

            if (-not (Test-Path -LiteralPath $targetParent -PathType Container)) {
                New-Item -ItemType Directory -Path $targetParent -Force | Out-Null
            }

            if (Test-Path -LiteralPath $targetPath -PathType Container) {
                if ($SkipExisting.IsPresent) {
                    Write-PSFMessage -Level Verbose -Message "Skipping existing repository target $($targetPath)."
                    continue
                }

                if (-not $Force.IsPresent) {
                    Write-PSFMessage -Level Warning -Message "Target directory $($targetPath) already exists. Use -Force to overwrite or -SkipExisting to ignore."
                    continue
                }

                # Remove the existing directory tree so cloning produces a clean checkout.
                Remove-Item -LiteralPath $targetPath -Recurse -Force
            }

            if (-not $PSCmdlet.ShouldProcess($targetPath, "Clone repository from $remoteUrl")) {
                continue
            }

            $argumentList = @("clone", "--recurse-submodules", "--", $remoteUrl, $targetPath)
            $cloneProcess = Start-Process -FilePath $resolvedGitPath -ArgumentList $argumentList -NoNewWindow -Wait -PassThru

            if ($cloneProcess.ExitCode -ne 0) {
                # Use PSFramework to log errors so they are captured by the module's logging configuration
                Write-PSFMessage -Level Error -Message "git clone for '$remoteUrl' failed with exit code $($cloneProcess.ExitCode)."
                continue
            }

            # Emit a summary object so callers can audit what was cloned.
            [pscustomobject]@{
                RemoteUrl  = $remoteUrl
                TargetPath = $targetPath
                Status     = "Cloned"
            }
        }
    }
}
