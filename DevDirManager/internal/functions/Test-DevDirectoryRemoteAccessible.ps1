function Test-DevDirectoryRemoteAccessible {
    <#
    .SYNOPSIS
        Internal helper that checks if a Git remote URL is accessible.

    .DESCRIPTION
        Tests whether a Git remote repository is accessible by executing `git ls-remote`
        with a timeout. This helps identify repositories that have been deleted, moved,
        or are otherwise unavailable.

        The function performs a lightweight check that only queries the remote refs
        without cloning or fetching data, making it suitable for checking multiple
        repositories.

    .PARAMETER RemoteUrl
        The Git remote URL to test for accessibility.

    .PARAMETER GitExecutable
        The path to the git.exe executable. Defaults to the configured value or 'git'.

    .PARAMETER TimeoutSeconds
        The maximum time in seconds to wait for the git ls-remote command to complete.
        Defaults to 10 seconds to avoid hanging on unresponsive remotes.

    .OUTPUTS
        [bool] Returns $true if the remote is accessible, $false otherwise.

    .EXAMPLE
        PS C:\> Test-DevDirectoryRemoteAccessible -RemoteUrl 'https://github.com/user/repo.git'

        Returns $true if the repository exists and is accessible.

    .EXAMPLE
        PS C:\> Test-DevDirectoryRemoteAccessible -RemoteUrl 'https://github.com/deleted/repo.git'

        Returns $false if the repository does not exist or is inaccessible.

    .NOTES
        Author    : Andi Bellstedt, Copilot
        Date      : 2025-11-09
        Version   : 1.0.0
        Keywords  : Git, Remote, Internal, Helper, Validation

    #>
    [CmdletBinding()]
    [OutputType([bool])]
    param(
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]
        $RemoteUrl,

        [Parameter()]
        [string]
        $GitExecutable = (Get-PSFConfigValue -FullName 'DevDirManager.Git.Executable' -Fallback 'git'),

        [Parameter()]
        [int]
        $TimeoutSeconds = 10
    )

    # Skip check for empty or null URLs
    if ([string]::IsNullOrWhiteSpace($RemoteUrl)) {
        Write-PSFMessage -Level Verbose -Message "Remote URL is empty, marking as inaccessible"
        return $false
    }

    # Attempt to execute git ls-remote with timeout
    try {
        Write-PSFMessage -Level Debug -Message "Checking remote accessibility for: $RemoteUrl"

        # Build the git ls-remote command
        $processInfo = New-Object System.Diagnostics.ProcessStartInfo
        $processInfo.FileName = $GitExecutable
        $processInfo.Arguments = "ls-remote --heads `"$RemoteUrl`""
        $processInfo.RedirectStandardOutput = $true
        $processInfo.RedirectStandardError = $true
        $processInfo.UseShellExecute = $false
        $processInfo.CreateNoWindow = $true

        $process = New-Object System.Diagnostics.Process
        $process.StartInfo = $processInfo

        # Start the process
        $null = $process.Start()

        # Wait for completion with timeout
        $completed = $process.WaitForExit($TimeoutSeconds * 1000)

        if (-not $completed) {
            # Timeout occurred
            Write-PSFMessage -Level Verbose -Message "Remote check timed out after $TimeoutSeconds seconds for: $RemoteUrl"
            $process.Kill()
            $process.Dispose()
            return $false
        }

        # Check exit code
        $exitCode = $process.ExitCode
        $process.Dispose()

        if ($exitCode -eq 0) {
            Write-PSFMessage -Level Debug -Message "Remote is accessible: $RemoteUrl"
            return $true
        } else {
            Write-PSFMessage -Level Verbose -Message "Remote is not accessible (exit code $exitCode): $RemoteUrl"
            return $false
        }
    } catch {
        Write-PSFMessage -Level Warning -Message "Error checking remote accessibility for $RemoteUrl : $($_.Exception.Message)"
        return $false
    }
}
