function Set-DevDirectoryFilter {
    <#
    .SYNOPSIS
        Sets or clears the SystemFilter property on repository objects.

    .DESCRIPTION
        Modifies the SystemFilter property on DevDirManager.Repository objects. The SystemFilter
        property determines which computer(s) a repository should be restored or synced to.
        When the filter pattern matches the current computer name (evaluated by
        Test-DevDirectorySystemFilter), the repository is included in restore/sync operations.
        When it doesn't match, the repository is skipped but remains in the repository list file.

        This cmdlet is designed for pipeline usage: pipe repository objects from
        Get-DevDirectory or Import-DevDirectoryList, set the filter, then pipe to
        Export-DevDirectoryList to persist the changes.

    .PARAMETER InputObject
        The repository object(s) to modify. Accepts objects from Get-DevDirectory or
        Import-DevDirectoryList via the pipeline.

    .PARAMETER SystemFilter
        The filter pattern to set. Supports the following syntax:
        - Empty string or $null: Matches all systems (no filtering)
        - "COMPUTER01": Exact match for a specific computer name
        - "DEV-*": Wildcard pattern matching computers starting with "DEV-"
        - "!SERVER-*": Exclusion pattern (matches all EXCEPT computers starting with "SERVER-")
        - "DEV-*,LAPTOP-*": Multiple patterns (comma-separated, OR logic)
        - "DEV-*,!DEV-TEST": Mixed patterns (include DEV-*, but exclude DEV-TEST)

    .PARAMETER Clear
        Clears the SystemFilter property (sets it to $null), effectively making the
        repository sync to all systems.

    .PARAMETER PassThru
        Returns the modified repository objects. Use this to chain with Export-DevDirectoryList
        or other cmdlets.

    .PARAMETER WhatIf
        Shows what would happen if the command runs. The command supports -WhatIf because it
        modifies object properties.

    .PARAMETER Confirm
        Prompts for confirmation before executing operations. The command supports -Confirm
        for safe execution when modifying repository filter settings.

    .EXAMPLE
        PS C:\> Import-DevDirectoryList -Path "repos.json" |
                    Where-Object RelativePath -like "Work\*" |
                    Set-DevDirectoryFilter -SystemFilter "WORK-PC*" -PassThru |
                    Export-DevDirectoryList -Path "repos.json"

        Sets the SystemFilter to "WORK-PC*" for all repositories under the "Work" folder,
        so they will only be restored/synced on computers whose names start with "WORK-PC".

    .EXAMPLE
        PS C:\> Get-DevDirectory -RootPath "C:\Dev" |
                    Set-DevDirectoryFilter -SystemFilter "DEV-*,!DEV-BUILD" -PassThru |
                    Export-DevDirectoryList -Path "repos.json"

        Scans repositories and sets a filter to include all DEV-* computers except DEV-BUILD,
        then exports to a repository list file.

    .EXAMPLE
        PS C:\> Import-DevDirectoryList -Path "repos.json" |
                    Set-DevDirectoryFilter -Clear -PassThru |
                    Export-DevDirectoryList -Path "repos.json"

        Clears the SystemFilter from all repositories, making them sync to all systems.

    .EXAMPLE
        PS C:\> $repos = Import-DevDirectoryList -Path "repos.json"
        PS C:\> $repos | Where-Object RelativePath -eq "Personal\MyProject" |
                    Set-DevDirectoryFilter -SystemFilter "HOME-PC" -PassThru
        PS C:\> $repos | Export-DevDirectoryList -Path "repos.json"

        Sets a specific filter on one repository while preserving others, using a variable
        to hold the collection.

    .NOTES
        Version   : 1.0.0
        Author    : Andi Bellstedt, Copilot
        Date      : 2026-01-05
        Keywords  : Git, Filter, Repository, SystemFilter

    .LINK
        https://github.com/AndiBellstedt/DevDirManager

    #>
    [CmdletBinding(
        DefaultParameterSetName = 'Set',
        SupportsShouldProcess = $true,
        ConfirmImpact = "Low"
    )]
    [OutputType('DevDirManager.Repository')]
    param(
        [Parameter(
            Mandatory = $true,
            ValueFromPipeline = $true,
            ValueFromPipelineByPropertyName = $true
        )]
        [ValidateNotNull()]
        [psobject[]]
        $InputObject,

        [Parameter(
            Mandatory = $true,
            ParameterSetName = 'Set'
        )]
        [AllowNull()]
        [AllowEmptyString()]
        [string]
        $SystemFilter,

        [Parameter(
            Mandatory = $true,
            ParameterSetName = 'Clear'
        )]
        [switch]
        $Clear,

        [Parameter()]
        [switch]
        $PassThru
    )

    begin {
        Write-PSFMessage -Level Debug -String 'SetDevDirectoryFilter.Start' -StringValues @($PSCmdlet.ParameterSetName, $SystemFilter, $Clear) -Tag "SetDevDirectoryFilter", "Start"

        # Determine the effective filter value based on parameter set
        $effectiveFilter = if ($PSCmdlet.ParameterSetName -eq 'Clear') {
            $null
        } else {
            # Treat empty string as null (both mean "no filter")
            if ([string]::IsNullOrWhiteSpace($SystemFilter)) { $null } else { $SystemFilter }
        }

        # Get localized action string for ShouldProcess
        $actionTemplate = Get-PSFLocalizedString -Module 'DevDirManager' -Name 'SetDevDirectoryFilter.ActionSet'
    }

    process {
        foreach ($repository in $InputObject) {
            # Skip null entries
            if (-not $repository) {
                continue
            }

            # Extract identifier for logging and ShouldProcess
            $repoIdentifier = if ($repository.PSObject.Properties.Match('RelativePath').Count -gt 0 -and $repository.RelativePath) {
                $repository.RelativePath
            } elseif ($repository.PSObject.Properties.Match('RemoteUrl').Count -gt 0 -and $repository.RemoteUrl) {
                $repository.RemoteUrl
            } else {
                "Unknown repository"
            }

            # Get current filter value for logging
            $currentFilter = if ($repository.PSObject.Properties.Match('SystemFilter').Count -gt 0) {
                $repository.SystemFilter
            } else {
                $null
            }

            # Build action description for ShouldProcess
            $actionDescription = if ($null -eq $effectiveFilter) {
                $actionTemplate -f @($repoIdentifier, "(cleared)")
            } else {
                $actionTemplate -f @($repoIdentifier, $effectiveFilter)
            }

            # Check ShouldProcess before making changes
            if (-not $PSCmdlet.ShouldProcess($repoIdentifier, $actionDescription)) {
                continue
            }

            Write-PSFMessage -Level Debug -String 'SetDevDirectoryFilter.Updating' -StringValues @($repoIdentifier, $currentFilter, $effectiveFilter) -Tag "SetDevDirectoryFilter", "Update"

            #region -- Set the SystemFilter property on the repository object

            # Check if the property exists; if not, add it using Add-Member.
            # Note: PSObject.Properties.Match() returns a collection, so we check Count.
            if ($repository.PSObject.Properties.Match('SystemFilter').Count -eq 0) {
                $repository | Add-Member -MemberType NoteProperty -Name 'SystemFilter' -Value $effectiveFilter -Force
            } else {
                $repository.SystemFilter = $effectiveFilter
            }

            #endregion Set the SystemFilter property on the repository object

            Write-PSFMessage -Level Verbose -String 'SetDevDirectoryFilter.Updated' -StringValues @($repoIdentifier, $effectiveFilter) -Tag "SetDevDirectoryFilter", "Result"

            # Return the modified object if PassThru is specified
            if ($PassThru.IsPresent) {
                $repository
            }
        }
    }

    end {
        Write-PSFMessage -Level Debug -String 'SetDevDirectoryFilter.Complete' -Tag "SetDevDirectoryFilter", "Complete"
    }
}
