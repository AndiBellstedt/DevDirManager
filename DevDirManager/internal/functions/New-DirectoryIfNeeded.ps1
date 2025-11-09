function New-DirectoryIfNeeded {
    <#
    .SYNOPSIS
        Creates a directory if it does not already exist.

    .DESCRIPTION
        This internal helper function checks if a directory exists and creates it if necessary.
        It uses the -Force parameter to ensure that parent directories are also created
        recursively, similar to 'mkdir -p' on Unix systems.

        The function is used across multiple public functions to ensure that target
        directories exist before file operations (writing repository lists, cloning
        repositories, etc.).

        Output from New-Item is automatically suppressed to keep function output clean.

        NOTE: This function does NOT implement ShouldProcess. Callers are responsible
        for implementing their own ShouldProcess logic before calling this function.
        This is an internal helper meant to be used within properly guarded code blocks.

    .PARAMETER Path
        The absolute path to the directory that should be created.
        Can be a single path or an array of paths.

    .OUTPUTS
        None (output is suppressed).

    .EXAMPLE
        PS C:\> New-DirectoryIfNeeded -Path "C:\Repos\Projects\MyProject"

        Creates the directory structure if it doesn't exist.

    .EXAMPLE
        PS C:\> New-DirectoryIfNeeded -Path "C:\Output\Reports" -ErrorAction Stop

        Creates the directory with explicit error handling, ensuring any failures are caught.

    .NOTES
        Version   : 1.0.1
        Author    : Copilot, Andi Bellstedt
        Date      : 2025-11-09
        Keywords  : directory, folder, creation, filesystem, path

    .LINK
        https://github.com/AndiBellstedt/DevDirManager
    #>
    [CmdletBinding()]
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseShouldProcessForStateChangingFunctions', '', Justification = 'This is an internal helper function. ShouldProcess is handled by the calling public functions.')]
    param (
        [Parameter(
            Mandatory = $true,
            ValueFromPipeline = $true,
            ValueFromPipelineByPropertyName = $true
        )]
        [ValidateNotNullOrEmpty()]
        [string[]]
        $Path
    )

    process {
        foreach ($directory in $Path) {
            Write-PSFMessage -Level Debug -Message "Processing directory: '$($directory)'" -Tag "NewDirectoryIfNeeded", "Start"

            # Skip processing if path is null, empty, or already exists
            if ([string]::IsNullOrEmpty($directory)) {
                Write-PSFMessage -Level Verbose -Message "Skipping empty directory path" -Tag "NewDirectoryIfNeeded", "Skip"
                continue
            }

            # Check if directory already exists
            if (Test-Path -LiteralPath $directory -PathType Container) {
                Write-PSFMessage -Level Verbose -Message "Directory already exists: '$($directory)'" -Tag "NewDirectoryIfNeeded", "Skip"
                continue
            }

            # Create the directory with Force to ensure parent directories are created
            Write-PSFMessage -Level Verbose -Message "Creating directory: '$($directory)'" -Tag "NewDirectoryIfNeeded", "Create"
            New-Item -ItemType Directory -Path $directory -Force -ErrorAction Stop | Out-Null
            Write-PSFMessage -Level Verbose -Message "Directory created successfully: '$($directory)'" -Tag "NewDirectoryIfNeeded", "Result"
        }
    }
}
