function Test-DevDirectorySystemFilter {
    <#
    .SYNOPSIS
        Tests if a repository should sync to the current computer based on its SystemFilter.

    .DESCRIPTION
        Evaluates the SystemFilter property against the current computer name
        to determine if the repository should be included in sync operations.

        Pattern syntax:
        - Null, empty, or "*" matches all systems
        - "WORKSTATION-01" exact match
        - "DEV-*" wildcard match (starts with DEV-)
        - "*-LAPTOP" wildcard match (ends with -LAPTOP)
        - "!SERVER-*" exclusion pattern (NOT on SERVER-* machines)
        - "DEV-*,LAPTOP-*" multiple patterns (OR logic)

        Exclusion patterns take precedence over inclusion patterns. If a computer
        matches any exclusion pattern, it will be rejected regardless of other
        inclusion patterns.

    .PARAMETER SystemFilter
        The filter pattern string from the repository. Can be null, empty,
        or contain one or more comma-separated patterns.

    .PARAMETER ComputerName
        The computer name to test against. Defaults to $env:COMPUTERNAME.

    .EXAMPLE
        PS C:\> Test-DevDirectorySystemFilter -SystemFilter "DEV-*"

        Returns $true if current computer name starts with "DEV-".

    .EXAMPLE
        PS C:\> Test-DevDirectorySystemFilter -SystemFilter "!SERVER-*" -ComputerName "WORKSTATION-01"

        Returns $true because "WORKSTATION-01" does not match the exclusion pattern "SERVER-*".

    .EXAMPLE
        PS C:\> Test-DevDirectorySystemFilter -SystemFilter "DEV-*,LAPTOP-*" -ComputerName "LAPTOP-WORK"

        Returns $true because "LAPTOP-WORK" matches the pattern "LAPTOP-*".

    .EXAMPLE
        PS C:\> Test-DevDirectorySystemFilter -SystemFilter "*"

        Returns $true because the wildcard "*" matches all systems.

    .EXAMPLE
        PS C:\> Test-DevDirectorySystemFilter -SystemFilter "DEV-*,!DEV-TEST" -ComputerName "DEV-TEST"

        Returns $false because "DEV-TEST" matches the exclusion pattern "!DEV-TEST",
        even though it also matches the inclusion pattern "DEV-*".

    .NOTES
        Version   : 1.0.0
        Author    : Andi Bellstedt, Copilot
        Date      : 2025-12-28
        Keywords  : Filter, System, Computer, Sync

    #>
    [CmdletBinding()]
    [OutputType([bool])]
    param(
        [Parameter(Mandatory = $true)]
        [AllowNull()]
        [AllowEmptyString()]
        [string]
        $SystemFilter,

        [Parameter()]
        [string]
        $ComputerName = $env:COMPUTERNAME
    )

    begin {
        # No initialization needed for this filter function.
    }

    process {
        #region -- Handle null, empty, or wildcard filter

        # Null or empty filter means match all systems.
        if ([string]::IsNullOrWhiteSpace($SystemFilter)) {
            Write-PSFMessage -Level Debug -Message "SystemFilter is empty, matching all systems"
            return $true
        }

        # Explicit wildcard "*" means match all systems.
        if ($SystemFilter.Trim() -eq "*") {
            Write-PSFMessage -Level Debug -Message "SystemFilter is '*', matching all systems"
            return $true
        }

        #endregion Handle null, empty, or wildcard filter

        #region -- Parse and evaluate filter patterns

        # Split the filter string by comma and trim each pattern.
        $patternList = $SystemFilter -split "," | ForEach-Object { $_.Trim() } | Where-Object { -not [string]::IsNullOrWhiteSpace($_) }

        $hasExclusion = $false
        $hasInclusion = $false
        $matchedExclusion = $false
        $matchedInclusion = $false

        foreach ($pattern in $patternList) {
            if ($pattern.StartsWith("!")) {
                # This is an exclusion pattern (negation).
                $hasExclusion = $true
                $excludePattern = $pattern.Substring(1)

                if ($ComputerName -like $excludePattern) {
                    $matchedExclusion = $true
                    Write-PSFMessage -Level Debug -Message "Computer '$($ComputerName)' matches exclusion pattern '$($excludePattern)'"
                }
            } else {
                # This is an inclusion pattern.
                $hasInclusion = $true

                if ($ComputerName -like $pattern) {
                    $matchedInclusion = $true
                    Write-PSFMessage -Level Debug -Message "Computer '$($ComputerName)' matches inclusion pattern '$($pattern)'"
                }
            }
        }

        #endregion Parse and evaluate filter patterns

        #region -- Determine final result

        # Exclusion patterns take precedence - if matched, always reject.
        if ($matchedExclusion) {
            Write-PSFMessage -Level Debug -Message "Computer '$($ComputerName)' excluded by filter '$($SystemFilter)'"
            return $false
        }

        # If inclusion patterns exist, must match at least one of them.
        if ($hasInclusion) {
            $result = $matchedInclusion
            Write-PSFMessage -Level Debug -Message "Computer '$($ComputerName)' inclusion check result: $($result)"
            return $result
        }

        # Only exclusion patterns existed and none matched - allow the computer.
        Write-PSFMessage -Level Debug -Message "Computer '$($ComputerName)' not excluded, allowing"
        return $true

        #endregion Determine final result
    }

    end {
        # No cleanup needed for this filter function.
    }
}
