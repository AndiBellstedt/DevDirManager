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
        The path to the git.exe executable. Defaults to the configured value or "git".

    .PARAMETER TimeoutSeconds
        The maximum time in seconds to wait for the git ls-remote command to complete.
        Defaults to 10 seconds to avoid hanging on unresponsive remotes.

    .OUTPUTS
        [bool] Returns $true if the remote is accessible, $false otherwise.

    .EXAMPLE
        PS C:\> Test-DevDirectoryRemoteAccessible -RemoteUrl "https://github.com/user/repo.git"

        Returns $true if the repository exists and is accessible.

    .EXAMPLE
        PS C:\> Test-DevDirectoryRemoteAccessible -RemoteUrl "https://github.com/deleted/repo.git"

        Returns $false if the repository does not exist or is inaccessible.

    .NOTES
        Author    : Andi Bellstedt, Copilot
        Date      : 2025-11-11
        Version   : 1.0.5
        Keywords  : Git, Remote, Internal, Helper, Validation

    .LINK
        https://github.com/AndiBellstedt/DevDirManager
    #>
    [CmdletBinding()]
    [OutputType([bool])]
    param (
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]
        $RemoteUrl,

        [Parameter()]
        [string]
        $GitExecutable = (Get-PSFConfigValue -FullName "DevDirManager.Git.Executable" -Fallback "git"),

        [Parameter()]
        [int]
        $TimeoutSeconds = 10
    )

    begin {
        $result = $false
    }

    process {
        #region -- Variable initialization
        $stdOutFile = $null
        $stdErrFile = $null
        $process = $null
        $shouldRun = $true
        $timedOut = $false
        #regionend Variable initialization

        if ([string]::IsNullOrWhiteSpace($RemoteUrl)) {
            Write-PSFMessage -Level Verbose -String "TestDevDirectoryRemoteAccessible.EmptyUrl"
            $shouldRun = $false
            return
        }

        try {
            Write-PSFMessage -Level Debug -String "TestDevDirectoryRemoteAccessible.CheckingRemote" -StringValues @($RemoteUrl)

            $stdOutFile = [System.IO.Path]::GetTempFileName()
            $stdErrFile = [System.IO.Path]::GetTempFileName()

            $process = Start-Process -FilePath $GitExecutable `
                -ArgumentList @("ls-remote", "--heads", "--", $RemoteUrl) `
                -NoNewWindow `
                -PassThru `
                -RedirectStandardOutput $stdOutFile `
                -RedirectStandardError $stdErrFile `
                -ErrorAction Stop

            if (-not $process) {
                Write-PSFMessage -Level Warning -String "TestDevDirectoryRemoteAccessible.ProcessStartFailed" -StringValues @($RemoteUrl) -Tag "TestDevDirectoryRemoteAccessible", "StartProcess"
                $shouldRun = $false
            }

            if ($shouldRun) {
                $stopwatch = [System.Diagnostics.Stopwatch]::StartNew()
                while (-not $process.HasExited) {
                    if ($stopwatch.Elapsed.TotalSeconds -ge $TimeoutSeconds) {
                        $timedOut = $true
                        Write-PSFMessage -Level Verbose -String "TestDevDirectoryRemoteAccessible.Timeout" -StringValues @($TimeoutSeconds, $RemoteUrl)
                        try {
                            $process.Kill()
                            Start-Sleep -Milliseconds 50
                        } catch {
                            Write-PSFMessage -Level Debug -Message "Failed to terminate git process for '$( $RemoteUrl )': $( $_.Exception.Message )" -Tag "TestDevDirectoryRemoteAccessible", "Timeout"
                        }

                        break
                    }

                    Start-Sleep -Milliseconds 200
                }
                $stopwatch.Stop()

                if ($timedOut) {
                    $result = $false
                } else {
                    $exitCode = $process.ExitCode
                    if ($exitCode -eq 0) {
                        Write-PSFMessage -Level Debug -String "TestDevDirectoryRemoteAccessible.Accessible" -StringValues @($RemoteUrl)
                        $result = $true
                    } else {
                        Write-PSFMessage -Level Verbose -String "TestDevDirectoryRemoteAccessible.NotAccessible" -StringValues @($exitCode, $RemoteUrl)
                        $result = $false
                    }
                }
            }
        } catch {
            if ($_.FullyQualifiedErrorId -like "*StartProcessCommand") {
                Write-PSFMessage -Level Warning -String "TestDevDirectoryRemoteAccessible.ProcessStartFailed" -StringValues @($RemoteUrl) -Tag "TestDevDirectoryRemoteAccessible", "StartProcess"
            }

            Write-PSFMessage -Level Warning -String "TestDevDirectoryRemoteAccessible.Error" -StringValues @($RemoteUrl, $_.Exception.Message)
            $result = $false
        } finally {
            if ($process) {
                try {
                    if (-not $process.HasExited) {
                        $process.Kill()
                        Start-Sleep -Milliseconds 50
                    }

                    $process.Dispose()
                } catch {
                    Write-PSFMessage -Level Debug -Message "Cleanup handling failed for git process targeting '$( $RemoteUrl )': $( $_.Exception.Message )" -Tag "TestDevDirectoryRemoteAccessible", "Cleanup"
                }
            }

            if ($stdOutFile -and (Test-Path -LiteralPath $stdOutFile)) {
                Remove-Item -LiteralPath $stdOutFile -Force -ErrorAction SilentlyContinue
            }

            if ($stdErrFile -and (Test-Path -LiteralPath $stdErrFile)) {
                Remove-Item -LiteralPath $stdErrFile -Force -ErrorAction SilentlyContinue
            }
        }
    }

    end {
        return $result
    }
}
