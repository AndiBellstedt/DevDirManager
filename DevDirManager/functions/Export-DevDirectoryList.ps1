function Export-DevDirectoryList {
    <#
    .SYNOPSIS
        Writes a repository list to disk in JSON or XML format.

    .DESCRIPTION
        Accepts repository list objects through the pipeline or the InputObject parameter, aggregates
        them in memory, and serializes the data to the specified output file. The output format can be
        chosen explicitly or inferred from the file extension.

    .PARAMETER InputObject
        Repository metadata objects, typically produced by Get-DevDirectory.

    .PARAMETER Path
        The destination file path for the serialized output.

    .PARAMETER Format
        The serialization format. Supports Json and Xml. When omitted, the format is inferred from the
        Path extension (.json or .xml).

    .PARAMETER WhatIf
        Shows what would happen if the command runs. The command supports -WhatIf because it may
        create directories or write files.

    .PARAMETER Confirm
        Prompts for confirmation before executing operations that change the file system. The command
        supports -Confirm because it uses ShouldProcess when writing the output file.

    .EXAMPLE
        PS C:\> Get-DevDirectory -RootPath "C:\Projects" | Export-DevDirectoryList -Path "repos.json"

        Exports the repository list to repos.json in JSON format.

    .NOTES
        Version   : 1.2.1
        Author    : Andi Bellstedt, Copilot
        Date      : 2025-01-24
        Keywords  : Git, Export, Serialization

    .LINK
        https://github.com/AndiBellstedt/DevDirManager

    #>
    [CmdletBinding(
        SupportsShouldProcess = $true,
        ConfirmImpact = "Low"
    )]
    [OutputType([void])]
    param(
        [Parameter(Mandatory = $true, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true)]
        [ValidateNotNull()]
        [psobject]
        $InputObject,

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]
        $Path,

        [Parameter()]
        [ValidateSet("CSV", "JSON", "XML")]
        [string]
        $Format
    )

    begin {
        # Normalize Format parameter to uppercase if provided
        if ($PSBoundParameters.ContainsKey('Format')) {
            $Format = $Format.ToUpper()
        }

        # Retrieve the default output format from configuration if not explicitly specified
        # This allows users to set a preferred format via Set-PSFConfig
        if (-not $PSBoundParameters.ContainsKey('Format')) {
            $defaultFormat = Get-PSFConfigValue -FullName 'DevDirManager.DefaultOutputFormat'
        }

        # Buffer all pipeline input into a List for single serialization in the end block
        # Using a List provides efficient Add() operations and avoids array resizing overhead
        $repositoryList = [System.Collections.Generic.List[psobject]]::new()
    }

    process {
        # Collect each pipeline object into the repository list buffer
        $repositoryList.Add($InputObject)
    }

    end {
        # Early exit if no repositories were provided via pipeline or parameter
        if ($repositoryList.Count -eq 0) {
            Write-PSFMessage -Level Verbose -String 'ExportDevDirectoryList.NoRepositoryEntries'
            return
        }

        # Determine the output format: use explicit Format parameter or infer from file extension
        $resolveFormatParams = @{
            Path         = $Path
            ErrorContext = "ExportDevDirectoryList"
        }
        if ($PSBoundParameters.ContainsKey('Format')) {
            $resolveFormatParams['Format'] = $Format
        }
        if ($defaultFormat) {
            $resolveFormatParams['DefaultFormat'] = $defaultFormat
        }
        $resolvedFormat = Resolve-RepositoryListFormat @resolveFormatParams

        # Extract the output directory path and resolve relative paths to current location
        $outputDirectory = Split-Path -Path $Path
        if ([string]::IsNullOrEmpty($outputDirectory) -or $outputDirectory -eq ".") {
            $outputDirectory = (Get-Location).ProviderPath
        }

        # Ensure the output directory exists before attempting to write the file
        if (-not [string]::IsNullOrEmpty($outputDirectory) -and -not (Test-Path -LiteralPath $outputDirectory -PathType Container)) {
            New-DirectoryIfNeeded -Path $outputDirectory
        }

        # Check for WhatIf/Confirm before performing the write operation
        $exportActionTemplate = Get-PSFLocalizedString -Module 'DevDirManager' -Name 'ExportDevDirectoryList.ActionExport'
        if (-not $PSCmdlet.ShouldProcess($Path, ($exportActionTemplate -f @($resolvedFormat)))) {
            return
        }

        # Serialize the repository list to the specified format
        switch ($resolvedFormat) {
            "CSV" {
                # Export to CSV with UTF8 encoding for cross-platform compatibility
                # Include all repository properties in a consistent order
                $repositoryList | Export-Csv -LiteralPath $Path -NoTypeInformation -Encoding UTF8
            }
            "JSON" {
                # Use Depth 5 to ensure nested properties are fully serialized
                # Set-Content with UTF8 ensures compatibility across systems
                $jsonContent = $repositoryList | ConvertTo-Json -Depth 5
                $jsonContent | Set-Content -LiteralPath $Path -Encoding UTF8
            }
            "XML" {
                # Export-Clixml handles depth automatically and preserves type information
                $repositoryList | Export-Clixml -Path $Path
            }
        }
    }
}
