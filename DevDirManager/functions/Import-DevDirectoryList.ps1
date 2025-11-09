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
        Version   : 1.2.3
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
        Write-PSFMessage -Level Debug -Message "Starting Import-DevDirectoryList from path: '$($Path)', Format: '$($Format)'" -Tag "ImportDevDirectoryList", "Start"

        # Normalize Format parameter to uppercase if provided
        if ($PSBoundParameters.ContainsKey('Format')) {
            $Format = $Format.ToUpper()
            Write-PSFMessage -Level System -Message "Using explicitly specified format: '$($Format)'" -Tag "ImportDevDirectoryList", "Configuration"
        }

        # Retrieve the default output format from configuration if not explicitly specified
        # This allows users to set a preferred format via Set-PSFConfig
        if (-not $PSBoundParameters.ContainsKey('Format')) {
            $defaultFormat = Get-PSFConfigValue -FullName 'DevDirManager.DefaultOutputFormat'
            if ($defaultFormat) {
                Write-PSFMessage -Level System -Message "Using default format from configuration: '$($defaultFormat)'" -Tag "ImportDevDirectoryList", "Configuration"
            }
        }
    }

    process {
        # Validate that the specified file exists before attempting to read it
        if (-not (Test-Path -LiteralPath $Path -PathType Leaf)) {
            Write-PSFMessage -Level Warning -Message "Import file not found: '$($Path)'" -Tag "ImportDevDirectoryList", "FileNotFound"
            $messageValues = @($Path)
            $messageTemplate = Get-PSFLocalizedString -Module 'DevDirManager' -Name 'ImportDevDirectoryList.FileNotFound'
            $message = $messageTemplate -f $messageValues
            Stop-PSFFunction -String 'ImportDevDirectoryList.FileNotFound' -StringValues $messageValues -EnableException $true -Cmdlet $PSCmdlet
            throw $message
        }

        Write-PSFMessage -Level Verbose -Message "Reading repository list from: '$($Path)'" -Tag "ImportDevDirectoryList", "Import"

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
        Write-PSFMessage -Level Verbose -Message "Resolved import format: '$($resolvedFormat)'" -Tag "ImportDevDirectoryList", "Format"

        # Deserialize the repository list from the specified format
        Write-PSFMessage -Level Debug -Message "Starting deserialization from $($resolvedFormat) format" -Tag "ImportDevDirectoryList", "Deserialization"

        switch ($resolvedFormat) {
            "CSV" {
                Write-PSFMessage -Level Debug -Message "Using Import-Csv for CSV deserialization" -Tag "ImportDevDirectoryList", "Deserialization"
                # Import CSV with UTF8 encoding
                $importedObjects = Import-Csv -LiteralPath $Path -Encoding UTF8

                Write-PSFMessage -Level Verbose -Message "Imported $(@($importedObjects).Count) objects from CSV, performing type conversions" -Tag "ImportDevDirectoryList", "TypeConversion"

                # Add the DevDirManager.Repository type to each imported object and handle type conversion
                foreach ($obj in $importedObjects) {
                    # Convert StatusDate from string to DateTime if present
                    if ($obj.PSObject.Properties.Match('StatusDate') -and -not [string]::IsNullOrWhiteSpace($obj.StatusDate)) {
                        try {
                            # Parse the date string - this will use current culture by default
                            # which matches Export-Csv behavior
                            $obj.StatusDate = [datetime]::Parse($obj.StatusDate)
                            Write-PSFMessage -Level Debug -Message "Successfully parsed StatusDate: '$($obj.StatusDate)'" -Tag "ImportDevDirectoryList", "TypeConversion"
                        } catch {
                            # If parsing fails, leave as string and log warning
                            Write-PSFMessage -Level Verbose -Message "Unable to parse StatusDate '{0}' as DateTime: {1}" -StringValues $obj.StatusDate, $_.Exception.Message -Tag "ImportDevDirectoryList", "TypeConversion"
                        }
                    }

                    # Add type name and output to pipeline
                    $obj | Add-RepositoryTypeName
                }

                Write-PSFMessage -Level Verbose -Message "Successfully imported $(@($importedObjects).Count) repositories from CSV file" -Tag "ImportDevDirectoryList", "Complete"
            }
            "JSON" {
                Write-PSFMessage -Level Debug -Message "Using ConvertFrom-Json for JSON deserialization" -Tag "ImportDevDirectoryList", "Deserialization"
                # Read the entire JSON file as a single string for ConvertFrom-Json
                $rawContent = Get-Content -LiteralPath $Path -Raw -Encoding UTF8

                # Handle empty or whitespace-only files gracefully by returning an empty array
                if ([string]::IsNullOrWhiteSpace($rawContent)) {
                    Write-PSFMessage -Level Verbose -Message "JSON file is empty or contains only whitespace" -Tag "ImportDevDirectoryList", "Import"
                    return
                }

                # Rehydrate the repository records from JSON
                $convertParams = @{ InputObject = $rawContent }
                if ($PSVersionTable.PSVersion.Major -ge 6) {
                    $convertParams['Depth'] = 5
                }

                $importedObjects = ConvertFrom-Json @convertParams

                Write-PSFMessage -Level Verbose -Message "Imported $(@($importedObjects).Count) objects from JSON, adding type information" -Tag "ImportDevDirectoryList", "TypeConversion"

                # Add the DevDirManager.Repository type to each imported object
                $importedObjects | Add-RepositoryTypeName

                Write-PSFMessage -Level Verbose -Message "Successfully imported $(@($importedObjects).Count) repositories from JSON file" -Tag "ImportDevDirectoryList", "Complete"
            }
            "XML" {
                Write-PSFMessage -Level Debug -Message "Using Import-Clixml for XML deserialization" -Tag "ImportDevDirectoryList", "Deserialization"
                # Import-Clixml automatically handles deserialization and type reconstruction
                $importedObjects = Import-Clixml -Path $Path

                Write-PSFMessage -Level Verbose -Message "Imported $(@($importedObjects).Count) objects from XML, adding type information" -Tag "ImportDevDirectoryList", "TypeConversion"

                # Add the DevDirManager.Repository type to each imported object
                $importedObjects | Add-RepositoryTypeName

                Write-PSFMessage -Level Verbose -Message "Successfully imported $(@($importedObjects).Count) repositories from XML file" -Tag "ImportDevDirectoryList", "Complete"
            }
        }
    }
}
