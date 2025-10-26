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
        Version   : 1.0.0
        Author    : Andi Bellstedt, Copilot
        Date      : 2025-10-26
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
        [ValidateSet("Json", "Xml")]
        [string]
        $Format
    )

    begin {
        # Buffer pipeline input so we can serialize once in the end block.
        $repositoryList = [System.Collections.Generic.List[psobject]]::new()
    }

    process {
        $repositoryList.Add($InputObject)
    }

    end {
        if ($repositoryList.Count -eq 0) {
            Write-PSFMessage -Level Verbose -Message "No repository entries received for export."
            return
        }

        $resolvedFormat = $Format
        if (-not $resolvedFormat) {
            $extension = [System.IO.Path]::GetExtension($Path)
            switch -Regex ($extension) {
                "^\.json$" { $resolvedFormat = "Json" }
                "^\.xml$" { $resolvedFormat = "Xml" }
                default { throw "Unable to infer export format from path '$Path'. Specify the Format parameter." }
            }
        }

        $outputDirectory = Split-Path -Path $Path
        if ([string]::IsNullOrEmpty($outputDirectory) -or $outputDirectory -eq ".") {
            $outputDirectory = (Get-Location).ProviderPath
        }

        if (-not [string]::IsNullOrEmpty($outputDirectory) -and -not (Test-Path -LiteralPath $outputDirectory -PathType Container)) {
            New-Item -ItemType Directory -Path $outputDirectory -Force | Out-Null
        }

        if (-not $PSCmdlet.ShouldProcess($Path, "Export repository list as $resolvedFormat")) {
            return
        }

        switch ($resolvedFormat) {
            "Json" {
                $jsonContent = $repositoryList | ConvertTo-Json -Depth 5
                $jsonContent | Set-Content -LiteralPath $Path -Encoding UTF8
            }
            "Xml" {
                $repositoryList | Export-Clixml -Path $Path
            }
        }
    }
}
