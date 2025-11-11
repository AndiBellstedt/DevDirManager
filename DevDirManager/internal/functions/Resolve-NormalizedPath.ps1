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
        Version   : 1.0.1
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
        Write-PSFMessage -Level Error -Message "Path parameter is null, empty, or whitespace" -Tag "ResolveNormalizedPath", "Error"
        throw "Path parameter cannot be null, empty, or whitespace."
    }

    Write-PSFMessage -Level Debug -Message "Resolving and normalizing path: '$($Path)', EnsureTrailingBackslash: $($EnsureTrailingBackslash)" -Tag "ResolveNormalizedPath", "Start"

    # Resolve the path to its canonical absolute form
    # This handles relative paths, environment variables, and provider-specific paths
    $resolvedPath = Resolve-Path -LiteralPath $Path -ErrorAction Stop
    $providerPath = $resolvedPath.ProviderPath
    Write-PSFMessage -Level Debug -Message "Resolved to provider path: '$($providerPath)'" -Tag "ResolveNormalizedPath", "Resolution"

    # Normalize using .NET GetFullPath to ensure consistent formatting
    # This handles redundant separators, "." and ".." segments, and case normalization
    $normalizedPath = [System.IO.Path]::GetFullPath($providerPath)
    Write-PSFMessage -Level Debug -Message "Normalized path: '$($normalizedPath)'" -Tag "ResolveNormalizedPath", "Normalization"

    # Add trailing backslash if requested (typically for directory operations)
    if ($EnsureTrailingBackslash -and -not $normalizedPath.EndsWith("\", [System.StringComparison]::Ordinal)) {
        $normalizedPath = "$($normalizedPath)\"
        Write-PSFMessage -Level Debug -Message "Added trailing backslash: '$($normalizedPath)'" -Tag "ResolveNormalizedPath", "Formatting"
    }

    Write-PSFMessage -Level Verbose -Message "Path normalized: '$($Path)' -> '$($normalizedPath)'" -Tag "ResolveNormalizedPath", "Result"
    return $normalizedPath
}
