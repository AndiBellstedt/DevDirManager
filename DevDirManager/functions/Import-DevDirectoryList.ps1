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
        Version   : 1.2.2
        Author    : Andi Bellstedt, Copilot
        Date      : 2025-11-09
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
            $messageValues = @($Path)
            $messageTemplate = Get-PSFLocalizedString -Module 'DevDirManager' -Name 'ImportDevDirectoryList.FileNotFound'
            $message = $messageTemplate -f $messageValues
            Stop-PSFFunction -String 'ImportDevDirectoryList.FileNotFound' -StringValues $messageValues -EnableException $true -Cmdlet $PSCmdlet
            throw $message
        }

        # Determine the import format: use explicit Format parameter or infer from file extension
        $resolveFormatParams = @{
            Path         = $Path
            ErrorContext = "ImportDevDirectoryList"
        }
        if ($PSBoundParameters.ContainsKey('Format')) {
            $resolveFormatParams['Format'] = $Format
        }
        if ($defaultFormat) {
            $resolveFormatParams['DefaultFormat'] = $defaultFormat
        }
        $resolvedFormat = Resolve-RepositoryListFormat @resolveFormatParams

        # Deserialize the repository list from the specified format
        switch ($resolvedFormat) {
            "CSV" {
                # Import CSV with UTF8 encoding
                $importedObjects = Import-Csv -LiteralPath $Path -Encoding UTF8

                # Add the DevDirManager.Repository type to each imported object and handle type conversion
                foreach ($obj in $importedObjects) {
                    # Convert StatusDate from string to DateTime if present
                    if ($obj.PSObject.Properties.Match('StatusDate') -and -not [string]::IsNullOrWhiteSpace($obj.StatusDate)) {
                        try {
                            # Parse the date string - this will use current culture by default
                            # which matches Export-Csv behavior
                            $obj.StatusDate = [datetime]::Parse($obj.StatusDate)
                        } catch {
                            # If parsing fails, leave as string and log warning
                            Write-PSFMessage -Level Verbose -Message "Unable to parse StatusDate '{0}' as DateTime: {1}" -StringValues $obj.StatusDate, $_.Exception.Message
                        }
                    }

                    # Add type name and output to pipeline
                    $obj | Add-RepositoryTypeName
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
                $importedObjects | Add-RepositoryTypeName
            }
            "XML" {
                # Import-Clixml automatically handles deserialization and type reconstruction
                $importedObjects = Import-Clixml -Path $Path

                # Add the DevDirManager.Repository type to each imported object
                $importedObjects | Add-RepositoryTypeName
            }
        }
    }
}
