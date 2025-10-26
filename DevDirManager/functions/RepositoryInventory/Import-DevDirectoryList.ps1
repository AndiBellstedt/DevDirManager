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
        Version   : 1.0.0
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
        [ValidateSet("Json", "Xml")]
        [string]
        $Format
    )

    process {
        # Validate that the specified file exists before attempting to read it
        if (-not (Test-Path -LiteralPath $Path -PathType Leaf)) {
            throw "The specified repository list file '$Path' does not exist."
        }

        # Determine the import format: use explicit Format parameter or infer from file extension
        $resolvedFormat = $Format
        if (-not $resolvedFormat) {
            $extension = [System.IO.Path]::GetExtension($Path)
            switch -Regex ($extension) {
                "^\.json$" { $resolvedFormat = "Json" }
                "^\.xml$" { $resolvedFormat = "Xml" }
                default { throw "Unable to infer import format from path '$Path'. Specify the Format parameter." }
            }
        }

        # Deserialize the repository list from the specified format
        switch ($resolvedFormat) {
            "Json" {
                # Read the entire JSON file as a single string for ConvertFrom-Json
                $rawContent = Get-Content -LiteralPath $Path -Raw -Encoding UTF8

                # Handle empty or whitespace-only files gracefully by returning an empty array
                if ([string]::IsNullOrWhiteSpace($rawContent)) {
                    return
                }

                # Rehydrate the repository records from JSON
                $importedObjects = $rawContent | ConvertFrom-Json -Depth 5

                # Add the DevDirManager.Repository type to each imported object
                foreach ($obj in $importedObjects) {
                    $obj.PSObject.TypeNames.Insert(0, 'DevDirManager.Repository')
                    # Output each object to the pipeline
                    $obj
                }
            }
            "Xml" {
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
