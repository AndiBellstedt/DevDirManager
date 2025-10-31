function ConvertTo-NormalizedRelativePath {
    <#
    .SYNOPSIS
        Internal helper that normalizes relative paths to a consistent backslash format.

    .DESCRIPTION
        Converts relative paths from various slash conventions (forward/back) to a canonical
        Windows-style backslash format. Handles edge cases like ".", empty strings, multiple
        consecutive slashes, and leading/trailing slashes. This ensures consistent path handling
        when synchronizing repository lists across different platforms or tools.

    .PARAMETER Path
        The relative path string to normalize.

    .OUTPUTS
        [string] The normalized relative path using backslashes, or "." for empty/root paths.

    .EXAMPLE
        PS C:\> ConvertTo-NormalizedRelativePath -Path "foo//bar"

        Returns "foo\bar" with forward slashes converted to backslashes.

    .EXAMPLE
        PS C:\> ConvertTo-NormalizedRelativePath -Path ""

        Returns "." for empty paths.

    .NOTES
        Author    : Andi Bellstedt, Copilot
        Date      : 2025-10-26
        Version   : 1.0.0
        Keywords  : Path, Internal, Helper

    #>
    [CmdletBinding()]
    [OutputType([string])]
    param(
        [Parameter(Mandatory = $true)]
        [AllowEmptyString()]
        [string]
        $Path
    )

    # Handle null, whitespace-only, or "." inputs uniformly as "." (current directory marker)
    if ([string]::IsNullOrWhiteSpace($Path) -or $Path -eq ".") {
        return "."
    }

    # Start normalization by trimming leading and trailing whitespace
    $cleaned = $Path.Trim()

    # Replace consecutive backslashes with a single forward slash (simplifies next steps)
    $cleaned = $cleaned -replace "\\\\", "/"

    # Remove any leading forward slashes (relative paths should not start with /)
    $cleaned = $cleaned -replace "^/+", ""

    # Remove any trailing forward slashes (relative paths should not end with /)
    $cleaned = $cleaned -replace "/+$", ""

    # After cleaning, if the string is now empty or whitespace, treat it as "."
    if ([string]::IsNullOrWhiteSpace($cleaned)) {
        return "."
    }

    # Finally, convert all forward slashes to backslashes for Windows-style paths
    # This ensures consistency when working with Join-Path and file system operations
    return ($cleaned -replace "/", "\\")
}
