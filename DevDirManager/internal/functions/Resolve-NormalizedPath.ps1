function Resolve-NormalizedPath {
    <#
    .SYNOPSIS
        Internal helper that resolves and normalizes a path to a canonical absolute form.

    .DESCRIPTION
        Resolves a path using Resolve-Path to get the absolute form, then normalizes it using
        System.IO.Path.GetFullPath to ensure consistent path handling. Optionally ensures the
        path ends with a trailing backslash for directory operations.

        This function provides a centralized, reusable way to handle path normalization across
        all module functions, ensuring consistent behavior and reducing code duplication.

    .PARAMETER Path
        The path to resolve and normalize. Can be relative or absolute.

    .PARAMETER EnsureTrailingBackslash
        If specified, ensures the normalized path ends with a backslash. This is useful for
        directory paths that will be used with Join-Path or URI-based operations.

    .OUTPUTS
        [string] The normalized absolute path, optionally with a trailing backslash.

    .EXAMPLE
        PS C:\> Resolve-NormalizedPath -Path "C:\Projects"

        Returns "C:\Projects" normalized to its canonical form.

    .EXAMPLE
        PS C:\> Resolve-NormalizedPath -Path "C:\Projects" -EnsureTrailingBackslash

        Returns "C:\Projects\" with a trailing backslash.

    .EXAMPLE
        PS C:\> Resolve-NormalizedPath -Path ".\relative\path"

        Resolves the relative path to its absolute form and normalizes it.

    .NOTES
        Author    : Andi Bellstedt, Copilot
        Date      : 2025-11-09
        Version   : 1.0.0
        Keywords  : Path, Internal, Helper, Normalization

    #>
    [CmdletBinding()]
    [OutputType([string])]
    param(
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]
        $Path,

        [Parameter()]
        [switch]
        $EnsureTrailingBackslash
    )

    # Handle edge case where Path might consist only of whitespace
    if ([string]::IsNullOrWhiteSpace($Path)) {
        throw "Path parameter cannot be null, empty, or whitespace."
    }

    # Resolve the path to its canonical absolute form
    # This handles relative paths, environment variables, and provider-specific paths
    $resolvedPath = Resolve-Path -LiteralPath $Path -ErrorAction Stop
    $providerPath = $resolvedPath.ProviderPath

    # Normalize using .NET GetFullPath to ensure consistent formatting
    # This handles redundant separators, "." and ".." segments, and case normalization
    $normalizedPath = [System.IO.Path]::GetFullPath($providerPath)

    # Add trailing backslash if requested (typically for directory operations)
    if ($EnsureTrailingBackslash -and -not $normalizedPath.EndsWith("\", [System.StringComparison]::Ordinal)) {
        $normalizedPath = "$($normalizedPath)\"
    }

    return $normalizedPath
}
