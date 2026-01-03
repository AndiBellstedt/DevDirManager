function Write-ConfigFileWithRetry {
    <#
    .SYNOPSIS
        Internal helper that writes configuration to a file with file-locking and retry logic.

    .DESCRIPTION
        Writes content to a configuration file using an atomic write pattern (write to temp file,
        then move/rename) with exclusive file locking. Includes retry logic for handling file
        locking conflicts when multiple processes might be accessing the same configuration file.

        The function acquires an exclusive lock on the target file before writing, ensuring that
        concurrent access from multiple processes is handled safely. If the file is locked by
        another process, the function will retry with exponential backoff.

        The function handles differences between PowerShell 5.1 (.NET Framework) and PowerShell 7+
        (.NET Core) for the file move operation.

    .PARAMETER Path
        The target file path to write the configuration to.

    .PARAMETER Content
        The content string to write to the file.

    .PARAMETER MaxRetries
        Maximum number of retry attempts if the file is locked. Default: 3.

    .PARAMETER MinDelayMs
        Minimum delay in milliseconds between retry attempts. Default: 100.

    .PARAMETER MaxDelayMs
        Maximum delay in milliseconds between retry attempts. Default: 500.

    .OUTPUTS
        None. Throws an exception if all retry attempts fail.

    .EXAMPLE
        PS C:\> Write-ConfigFileWithRetry -Path "C:\Config\settings.json" -Content '{"setting": "value"}'

        Writes the JSON content to the specified file with file locking and retry logic.

    .NOTES
        Author    : Andi Bellstedt, Copilot
        Date      : 2025-12-30
        Version   : 1.2.0
        Keywords  : Configuration, FileWrite, Internal, Helper, FileLock

    #>
    [CmdletBinding()]
    [OutputType([void])]
    param(
        [Parameter(Mandatory = $true)]
        [string]
        $Path,

        [Parameter(Mandatory = $true)]
        [string]
        $Content,

        [Parameter()]
        [int]
        $MaxRetries = 3,

        [Parameter()]
        [int]
        $MinDelayMs = 100,

        [Parameter()]
        [int]
        $MaxDelayMs = 500
    )

    $attempt = 0
    $success = $false
    $tempPath = $null
    $lockFileStream = $null

    Write-PSFMessage -Level Debug -String "WriteConfigFileWithRetry.Start" -StringValues @($Path) -Tag "WriteConfigFileWithRetry", "Start"

    while (-not $success -and $attempt -lt $MaxRetries) {
        $attempt++

        try {
            #region -- Acquire exclusive lock on the target file

            # Try to acquire an exclusive lock on the target file (or create it if it doesn't exist).
            # This ensures that no other process can read or write the file while we're updating it.
            Write-PSFMessage -Level VeryVerbose -String "WriteConfigFileWithRetry.AcquiringLock" -StringValues @($Path, $attempt) -Tag "WriteConfigFileWithRetry", "Lock"

            $lockFileStream = [System.IO.File]::Open(
                $Path,
                [System.IO.FileMode]::OpenOrCreate,
                [System.IO.FileAccess]::ReadWrite,
                [System.IO.FileShare]::None  # Exclusive lock - no sharing
            )

            Write-PSFMessage -Level VeryVerbose -String "WriteConfigFileWithRetry.LockAcquired" -StringValues @($Path) -Tag "WriteConfigFileWithRetry", "Lock"

            #endregion Acquire exclusive lock on the target file

            #region -- Write content using atomic temp file pattern

            # Create a temporary file for atomic write.
            $tempPath = "$($Path).tmp.$([System.IO.Path]::GetRandomFileName())"

            # Write to temporary file first.
            [System.IO.File]::WriteAllText($tempPath, $Content, [System.Text.Encoding]::UTF8)

            # Close the lock before moving (we need to release the lock to allow the move to overwrite).
            $lockFileStream.Close()
            $lockFileStream.Dispose()
            $lockFileStream = $null

            # Move (rename) temporary file to target - this is atomic on most file systems.
            # Note: .NET Framework (PS5.1) only has 2-parameter Move(), .NET Core (PS7+) has 3-parameter overload with overwrite flag.
            if ($PSVersionTable.PSVersion.Major -ge 6) {
                # PowerShell 7+ with .NET Core - use 3-parameter overload with overwrite.
                [System.IO.File]::Move($tempPath, $Path, $true)
            } else {
                # PowerShell 5.1 with .NET Framework - delete target first, then move.
                if (Test-Path -Path $Path -PathType Leaf) {
                    [System.IO.File]::Delete($Path)
                }
                [System.IO.File]::Move($tempPath, $Path)
            }

            #endregion Write content using atomic temp file pattern

            $success = $true
            Write-PSFMessage -Level Verbose -String "WriteConfigFileWithRetry.Success" -StringValues @($Path, $attempt) -Tag "WriteConfigFileWithRetry", "FileWrite"

        } catch [System.IO.IOException] {
            # File might be locked by another process.
            Write-PSFMessage -Level Warning -String "WriteConfigFileWithRetry.IOError" -StringValues @($attempt, $_.Exception.Message) -Tag "WriteConfigFileWithRetry", "FileWrite", "Retry" -ErrorRecord $_

            # Clean up resources.
            if ($lockFileStream) {
                try { $lockFileStream.Close(); $lockFileStream.Dispose() } catch { Write-PSFMessage -Level Debug -String "Failed to dispose lock file stream" -ErrorRecord $_ }
                $lockFileStream = $null
            }
            if ($tempPath -and (Test-Path -Path $tempPath -PathType Leaf)) {
                Remove-Item -Path $tempPath -Force -ErrorAction SilentlyContinue
            }

            if ($attempt -lt $MaxRetries) {
                # Random delay between retries to reduce collision chance.
                $delay = Get-Random -Minimum $MinDelayMs -Maximum $MaxDelayMs
                Write-PSFMessage -Level Verbose -String "WriteConfigFileWithRetry.Retrying" -StringValues @($delay, ($MaxRetries - $attempt)) -Tag "WriteConfigFileWithRetry", "Retry"
                Start-Sleep -Milliseconds $delay
            }

        } catch {
            # Non-IOException - log, clean up and rethrow.
            Write-PSFMessage -Level Error -String "WriteConfigFileWithRetry.UnexpectedError" -StringValues @($_.Exception.Message) -Tag "WriteConfigFileWithRetry", "Error" -ErrorRecord $_

            if ($lockFileStream) {
                try { $lockFileStream.Close(); $lockFileStream.Dispose() } catch { Write-PSFMessage -Level Debug -String "Failed to dispose lock file stream" -ErrorRecord $_ }
                $lockFileStream = $null
            }
            if ($tempPath -and (Test-Path -Path $tempPath -PathType Leaf)) {
                Remove-Item -Path $tempPath -Force -ErrorAction SilentlyContinue
            }

            $errorMessage = Get-PSFLocalizedString -Module "DevDirManager" -Name "WriteConfigFileWithRetry.UnexpectedError"
            $errorMessage = $errorMessage -f $_.Exception.Message
            throw $errorMessage
        }
    }

    if (-not $success) {
        $errorMessage = Get-PSFLocalizedString -Module "DevDirManager" -Name "WriteConfigFileWithRetry.AllAttemptsFailed"
        $errorMessage = $errorMessage -f $MaxRetries
        Write-PSFMessage -Level Error -String "WriteConfigFileWithRetry.AllAttemptsFailed" -StringValues @($MaxRetries) -Tag "WriteConfigFileWithRetry", "Error"
        throw $errorMessage
    }

    Write-PSFMessage -Level Debug -String "WriteConfigFileWithRetry.Complete" -StringValues @($Path) -Tag "WriteConfigFileWithRetry", "Complete"
}
