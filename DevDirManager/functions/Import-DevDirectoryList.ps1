function Import-DevDirectoryList {
    <#
    .SYNOPSIS
        Imports a repository list from a JSON or XML file.

    .DESCRIPTION
        Reads a serialized repository list and converts it back to PowerShell objects. The function
        automatically detects the format from the file extension unless a specific format is supplied.

    .PARAMETER Path
        The path to the serialized repository list file.

    .PARAMETER Format
        The expected format of the file: Json or Xml. Defaults to inferring the format from the file
        extension.

    .EXAMPLE
        PS C:\> Import-DevDirectoryList -Path "repos.json"

        Reads repository metadata from the JSON file and returns it to the pipeline.

    .NOTES
        Version   : 1.1.0
        Author    : Andi Bellstedt, Copilot
        Date      : 2025-10-26
        Keywords  : Git, Import, Serialization

    .LINK
        https://github.com/AndiBellstedt/DevDirManager

    #>
    [CmdletBinding()]
    [OutputType('DevDirManager.Repository')]
    param(
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
    }

    process {
        # Validate that the specified file exists before attempting to read it
        if (-not (Test-Path -LiteralPath $Path -PathType Leaf)) {
            $message = "The specified repository list file '$($Path)' does not exist."
            Stop-PSFFunction -Message $message -EnableException $true -Cmdlet $PSCmdlet
            throw $message
        }

        # Determine the import format: use explicit Format parameter or infer from file extension
        $resolvedFormat = $Format
        if (-not $resolvedFormat) {
            $extension = [System.IO.Path]::GetExtension($Path).ToLower()
            switch -Regex ($extension) {
                "^\.csv$" { $resolvedFormat = "CSV" }
                "^\.json$" { $resolvedFormat = "JSON" }
                "^\.xml$" { $resolvedFormat = "XML" }
                default {
                    # Use the configured default format if file extension doesn't match
                    if ($defaultFormat) {
                        $resolvedFormat = $defaultFormat
                        Write-PSFMessage -Level Verbose -Message "Using configured default format '$($resolvedFormat)' for file '$($Path)'."
                    } else {
                        $message = "Unable to infer import format from path '$($Path)'. Specify the Format parameter."
                        Stop-PSFFunction -Message $message -EnableException $true -Cmdlet $PSCmdlet
                        throw $message
                    }
                }
            }
        }

        # Deserialize the repository list from the specified format
        switch ($resolvedFormat) {
            "CSV" {
                # Import CSV with UTF8 encoding
                $importedObjects = Import-Csv -LiteralPath $Path -Encoding UTF8

                # Add the DevDirManager.Repository type to each imported object
                foreach ($obj in $importedObjects) {
                    $obj.PSObject.TypeNames.Insert(0, 'DevDirManager.Repository')
                    # Output each object to the pipeline
                    $obj
                }
            }
            "JSON" {
                # Read the entire JSON file as a single string for ConvertFrom-Json
                $rawContent = Get-Content -LiteralPath $Path -Raw -Encoding UTF8

                # Handle empty or whitespace-only files gracefully by returning an empty array
                if ([string]::IsNullOrWhiteSpace($rawContent)) {
                    return
                }

                # Rehydrate the repository records from JSON
                $convertParams = @{ InputObject = $rawContent }
                if ($PSVersionTable.PSVersion.Major -ge 6) {
                    $convertParams['Depth'] = 5
                }

                $importedObjects = ConvertFrom-Json @convertParams

                # Add the DevDirManager.Repository type to each imported object
                foreach ($obj in $importedObjects) {
                    $obj.PSObject.TypeNames.Insert(0, 'DevDirManager.Repository')
                    # Output each object to the pipeline
                    $obj
                }
            }
            "XML" {
                # Import-Clixml automatically handles deserialization and type reconstruction
                $importedObjects = Import-Clixml -Path $Path

                # Add the DevDirManager.Repository type to each imported object
                foreach ($obj in $importedObjects) {
                    $obj.PSObject.TypeNames.Insert(0, 'DevDirManager.Repository')
                    # Output each object to the pipeline
                    $obj
                }
            }
        }
    }
}
