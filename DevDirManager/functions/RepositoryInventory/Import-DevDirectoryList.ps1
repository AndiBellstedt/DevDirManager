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
    [OutputType([object[]])]
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
        if (-not (Test-Path -LiteralPath $Path -PathType Leaf)) {
            throw "The specified repository list file '$Path' does not exist."
        }

        $resolvedFormat = $Format
        if (-not $resolvedFormat) {
            $extension = [System.IO.Path]::GetExtension($Path)
            switch -Regex ($extension) {
                "^\.json$" { $resolvedFormat = "Json" }
                "^\.xml$" { $resolvedFormat = "Xml" }
                default { throw "Unable to infer import format from path '$Path'. Specify the Format parameter." }
            }
        }

        switch ($resolvedFormat) {
            "Json" {
                $rawContent = Get-Content -LiteralPath $Path -Raw -Encoding UTF8
                if ([string]::IsNullOrWhiteSpace($rawContent)) {
                    return @()
                }

                # Rehydrate the repository records for downstream processing and ensure an array is returned.
                ($rawContent | ConvertFrom-Json -Depth 5) -as [object[]]
            }
            "Xml" {
                Import-Clixml -Path $Path
            }
        }
    }
}
