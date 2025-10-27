function Publish-DevDirectoryList {
    <#
    .SYNOPSIS
        Publishes a repository list to a GitHub Gist named "GitRepositoryList".

    .DESCRIPTION
        Reads repository metadata either from pipeline input or from a JSON file produced by
        Export-DevDirectoryList and uploads it to a GitHub Gist named "GitRepositoryList". The cmdlet can
        create a new gist or update an existing one when a matching description or explicit gist
        identifier is supplied. Use the AccessToken parameter with a GitHub personal access token that has
        gist scope.

    .PARAMETER Path
        Specifies the path to a JSON file created by Export-DevDirectoryList whose contents should be
        uploaded to the gist. This parameter belongs to the FromPath parameter set.

    .PARAMETER InputObject
        Accepts repository metadata objects (as produced by Get-DevDirectory) directly from the pipeline.
        The objects are converted to JSON before uploading. This parameter belongs to the FromInput
        parameter set.

    .PARAMETER AccessToken
        The GitHub personal access token with permissions to read and write gists. The token must include
        the gist scope.

    .PARAMETER GistId
        When provided, updates the gist with the specified identifier instead of searching by description.

    .PARAMETER Public
        Publishes the gist as public. By default a secret gist is created or updated.

    .PARAMETER ApiUrl
        Overrides the GitHub API base URL. Defaults to https://api.github.com and is primarily intended
        for GitHub Enterprise deployments.

    .PARAMETER WhatIf
        Shows what would happen if the command runs. The command supports -WhatIf because it may
        perform remote HTTP updates when creating or updating a gist.

    .PARAMETER Confirm
        Prompts for confirmation before executing operations that change remote resources. The command
        supports -Confirm because it uses ShouldProcess when creating or updating the gist.

    .EXAMPLE
        PS C:\> Publish-DevDirectoryList -Path ".\repos.json" -AccessToken (Get-Secret "GitHubGistToken")

        Reads the repository list from repos.json and uploads it to a secret gist named GitRepositoryList.

    .EXAMPLE
        PS C:\> Get-DevDirectory -RootPath ".\Repos" | Publish-DevDirectoryList -AccessToken $token -Public

        Streams repository metadata directly from the pipeline and publishes it to a public gist.

    .NOTES
        Version   : 1.1.1
        Author    : Andi Bellstedt, Copilot
        Date      : 2025-10-27
        Keywords  : Git, Gist, Publish

    .LINK
        https://github.com/AndiBellstedt/DevDirManager

    #>
    [CmdletBinding(
        SupportsShouldProcess = $true,
        DefaultParameterSetName = "FromPath"
    )]
    [OutputType('DevDirManager.GistResult')]
    param(
        [Parameter(
            ParameterSetName = "FromPath",
            Mandatory = $true
        )]
        [ValidateNotNullOrEmpty()]
        [string]
        $Path,

        [Parameter(
            ParameterSetName = "FromInput",
            Mandatory = $true,
            ValueFromPipeline = $true,
            ValueFromPipelineByPropertyName = $true
        )]
        [ValidateNotNull()]
        [psobject]
        $InputObject,

        [Parameter(Mandatory = $true)]
        [ValidateNotNull()]
        [System.Security.SecureString]
        $AccessToken,

        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [string]
        $GistId,

        [Parameter()]
        [switch]
        $Public,

        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [string]
        $ApiUrl = "https://api.github.com"
    )

    begin {
        # Collect data so we can upload once per invocation.
        $repositoryList = [System.Collections.Generic.List[psobject]]::new()

        $tokenPointer = [System.IntPtr]::Zero
        try {
            $tokenPointer = [System.Runtime.InteropServices.Marshal]::SecureStringToGlobalAllocUnicode($AccessToken)
            $resolvedToken = [System.Runtime.InteropServices.Marshal]::PtrToStringUni($tokenPointer)
        } finally {
            if ($tokenPointer -ne [System.IntPtr]::Zero) {
                [System.Runtime.InteropServices.Marshal]::ZeroFreeGlobalAllocUnicode($tokenPointer)
            }
        }

        if ([string]::IsNullOrWhiteSpace($resolvedToken)) {
            $message = "The provided access token is empty after conversion."
            Stop-PSFFunction -Message $message -EnableException $true -Cmdlet $PSCmdlet
            throw $message
        }

        $requestHeaders = @{
            Authorization = "Bearer $resolvedToken"
            "User-Agent"  = "DevDirManager"
            Accept        = "application/vnd.github+json"
        }

        $gistEndpoint = "$($ApiUrl.TrimEnd("/"))/gists"
    }

    process {
        if ($PSCmdlet.ParameterSetName -eq "FromInput") {
            $repositoryList.Add($InputObject)
        }
    }

    end {
        try {
            if ($PSCmdlet.ParameterSetName -eq "FromInput") {
                if ($repositoryList.Count -eq 0) {
                    Write-PSFMessage -Level Verbose -Message "No repository metadata was received from the pipeline."
                    return
                }

                $jsonContent = $repositoryList | ConvertTo-Json -Depth 6
            } else {
                $resolvedPath = Resolve-Path -LiteralPath $Path -ErrorAction Stop
                $extension = [System.IO.Path]::GetExtension($resolvedPath).ToLower()

                # Determine if we need to convert the file format to JSON
                switch -Regex ($extension) {
                    "^\.json$" {
                        # File is already JSON, read it directly
                        $jsonContent = Get-Content -LiteralPath $resolvedPath -Raw -Encoding UTF8
                    }
                    "^\.csv$|^\.xml$" {
                        # Import the file using Import-DevDirectoryList and convert to JSON
                        $importedData = Import-DevDirectoryList -Path $resolvedPath
                        $jsonContent = $importedData | ConvertTo-Json -Depth 6
                    }
                    default {
                        # Assume it's JSON if extension is unknown
                        $jsonContent = Get-Content -LiteralPath $resolvedPath -Raw -Encoding UTF8
                    }
                }
            }

            if ([string]::IsNullOrWhiteSpace($jsonContent)) {
                Write-PSFMessage -Level Warning -Message "The repository list content is empty. Nothing will be published."
                return
            }

            if (-not $GistId) {
                try {
                    $existingGistList = Invoke-RestMethod -Method Get -Uri "$($gistEndpoint)?per_page=100" -Headers $requestHeaders -ErrorAction Stop
                    $matchingGist = $existingGistList | Where-Object description -eq "GitRepositoryList" | Select-Object -First 1
                    if ($matchingGist) {
                        $GistId = $matchingGist.id
                    }
                } catch {
                    Write-PSFMessage -Level Verbose -Message "Failed to query existing gists: $($_.Exception.Message)"
                }
            }

            $payload = @{
                description = "GitRepositoryList"
                public      = $Public.IsPresent
                files       = @{
                    "GitRepositoryList.json" = @{ content = $jsonContent }
                }
            } | ConvertTo-Json -Depth 6

            $targetLabel = if ($GistId) { "Update gist $($GistId)" } else { "Create gist GitRepositoryList" }
            if (-not $PSCmdlet.ShouldProcess($targetLabel, "Publish DevDirManager repository list to GitHub Gist")) {
                return
            }

            if ($GistId) {
                $response = Invoke-RestMethod -Method Patch -Uri "$($gistEndpoint)/$GistId" -Headers $requestHeaders -Body $payload -ContentType "application/json"
            } else {
                $response = Invoke-RestMethod -Method Post -Uri $gistEndpoint -Headers $requestHeaders -Body $payload -ContentType "application/json"
            }

            # Return summary details so callers have the gist identifier for follow-up automation.
            [pscustomobject]@{
                PSTypeName  = 'DevDirManager.GistResult'
                Description = $response.description
                GistId      = $response.id
                HtmlUrl     = $response.html_url
                Public      = $response.public
                Files       = $response.files.Keys
            }
        } finally {
            if ($null -ne $requestHeaders -and $requestHeaders.ContainsKey("Authorization")) {
                $requestHeaders["Authorization"] = $null
            }

            $resolvedToken = $null
        }
    }
}
