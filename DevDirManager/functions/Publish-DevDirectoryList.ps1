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

    .EXAMPLE
        PS C:\> $token = Read-Host -AsSecureString -Prompt "GitHub PAT"
        PS C:\> Publish-DevDirectoryList -Path "repos.csv" -AccessToken $token

        Prompts for GitHub Personal Access Token securely, then publishes the CSV file
        (automatically converted to JSON for Gist compatibility).

    .EXAMPLE
        PS C:\> Get-DevDirectory | Publish-DevDirectoryList -AccessToken $token -GistId "abc123def456"

        Updates an existing gist by providing its ID instead of searching by description.

    .EXAMPLE
        PS C:\> Publish-DevDirectoryList -Path "repos.xml" -AccessToken $token -Verbose

        Publishes with verbose output showing conversion steps, API calls, and gist details.
        XML format is automatically converted to JSON before publishing.

    .EXAMPLE
        PS C:\> Get-DevDirectory -RootPath "C:\Projects" | Where-Object RemoteUrl -like "*github.com*" | Publish-DevDirectoryList -AccessToken $token -Public

        Publishes only GitHub repositories to a public gist, filtering before publication.

    .NOTES
        Version   : 1.1.5
        Author    : Andi Bellstedt, Copilot
        Date      : 2025-11-09
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
        Write-PSFMessage -Level Debug -String 'PublishDevDirectoryList.Start' -StringValues @($PSCmdlet.ParameterSetName, $Public, $GistId) -Tag "PublishDevDirectoryList", "Start"

        # Collect data so we can upload once per invocation.
        $repositoryList = [System.Collections.Generic.List[psobject]]::new()

        Write-PSFMessage -Level System -String 'PublishDevDirectoryList.AuthenticationDecrypt' -Tag "PublishDevDirectoryList", "Authentication"
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
            Write-PSFMessage -Level Error -String 'PublishDevDirectoryList.TokenEmptyError' -Tag "PublishDevDirectoryList", "Authentication"
            $messageTemplate = Get-PSFLocalizedString -Module 'DevDirManager' -Name 'PublishDevDirectoryList.TokenEmpty'
            $message = $messageTemplate
            Stop-PSFFunction -String 'PublishDevDirectoryList.TokenEmpty' -EnableException $true -Cmdlet $PSCmdlet
            throw $message
        }

        Write-PSFMessage -Level System -String 'PublishDevDirectoryList.ConfigurationApiUrl' -StringValues @($ApiUrl) -Tag "PublishDevDirectoryList", "Configuration"
        $requestHeaders = @{
            Authorization = "Bearer $resolvedToken"
            "User-Agent"  = "DevDirManager"
            Accept        = "application/vnd.github+json"
        }

        $gistEndpoint = "$($ApiUrl.TrimEnd("/"))/gists"

        $publishAction = Get-PSFLocalizedString -Module 'DevDirManager' -Name 'PublishDevDirectoryList.ActionPublish'
        $targetLabelCreate = Get-PSFLocalizedString -Module 'DevDirManager' -Name 'PublishDevDirectoryList.TargetLabelCreate'
        $targetLabelUpdateTemplate = Get-PSFLocalizedString -Module 'DevDirManager' -Name 'PublishDevDirectoryList.TargetLabelUpdate'
    }

    process {
        if ($PSCmdlet.ParameterSetName -eq "FromInput") {
            Write-PSFMessage -Level Debug -String 'PublishDevDirectoryList.CollectPipelineObject' -Tag "PublishDevDirectoryList", "Collect"
            $repositoryList.Add($InputObject)
        }
    }

    end {
        try {
            if ($PSCmdlet.ParameterSetName -eq "FromInput") {
                if ($repositoryList.Count -eq 0) {
                    Write-PSFMessage -Level Verbose -String 'PublishDevDirectoryList.NoPipelineData' -Tag "PublishDevDirectoryList", "Validation"
                    return
                }

                Write-PSFMessage -Level Verbose -String 'PublishDevDirectoryList.ConvertToJson' -StringValues @($repositoryList.Count) -Tag "PublishDevDirectoryList", "Serialization"
                $jsonContent = $repositoryList | ConvertTo-Json -Depth 6
            } else {
                Write-PSFMessage -Level Verbose -String 'PublishDevDirectoryList.ReadFile' -StringValues @($Path) -Tag "PublishDevDirectoryList", "FileRead"
                $resolvedPath = Resolve-Path -LiteralPath $Path -ErrorAction Stop

                # Determine the file format to decide how to read the content
                # Since Publish always outputs JSON, we need to convert non-JSON formats
                $fileFormat = Resolve-RepositoryListFormat -Path $resolvedPath -ErrorContext "PublishDevDirectoryList"
                Write-PSFMessage -Level Verbose -String 'PublishDevDirectoryList.FormatDetected' -StringValues @($fileFormat) -Tag "PublishDevDirectoryList", "Format"

                # Read or convert file content to JSON based on format
                switch ($fileFormat) {
                    "JSON" {
                        Write-PSFMessage -Level Debug -String 'PublishDevDirectoryList.ReadJsonDirect' -Tag "PublishDevDirectoryList", "Serialization"
                        # File is already JSON, read it directly
                        $jsonContent = Get-Content -LiteralPath $resolvedPath -Raw -Encoding UTF8
                    }
                    default {
                        Write-PSFMessage -Level Debug -String 'PublishDevDirectoryList.ConvertFormat' -StringValues @($fileFormat) -Tag "PublishDevDirectoryList", "Serialization"
                        # CSV or XML: Import the file using Import-DevDirectoryList and convert to JSON
                        $importedData = Import-DevDirectoryList -Path $resolvedPath
                        $jsonContent = $importedData | ConvertTo-Json -Depth 6
                    }
                }
            }

            if ([string]::IsNullOrWhiteSpace($jsonContent)) {
                Write-PSFMessage -Level Warning -String 'PublishDevDirectoryList.EmptyContent' -Tag "PublishDevDirectoryList", "Validation"
                return
            }

            if (-not $GistId) {
                Write-PSFMessage -Level Verbose -String 'PublishDevDirectoryList.SearchGist' -Tag "PublishDevDirectoryList", "GistQuery"
                try {
                    $existingGistList = Invoke-RestMethod -Method Get -Uri "$($gistEndpoint)?per_page=100" -Headers $requestHeaders -ErrorAction Stop
                    $matchingGist = $existingGistList | Where-Object description -eq "GitRepositoryList" | Select-Object -First 1
                    if ($matchingGist) {
                        $GistId = $matchingGist.id
                        Write-PSFMessage -Level Verbose -String 'PublishDevDirectoryList.GistFound' -StringValues @($GistId) -Tag "PublishDevDirectoryList", "GistQuery"
                    } else {
                        Write-PSFMessage -Level Verbose -String 'PublishDevDirectoryList.GistNotFound' -Tag "PublishDevDirectoryList", "GistQuery"
                    }
                } catch {
                    Write-PSFMessage -Level Verbose -String 'PublishDevDirectoryList.QueryGistFailed' -StringValues @($_.Exception.Message) -Tag "PublishDevDirectoryList", "GistQuery"
                }
            } else {
                Write-PSFMessage -Level Verbose -String 'PublishDevDirectoryList.UsingProvidedGistId' -StringValues @($GistId) -Tag "PublishDevDirectoryList", "Configuration"
            }

            $payload = @{
                description = "GitRepositoryList"
                public      = $Public.IsPresent
                files       = @{
                    "GitRepositoryList.json" = @{ content = $jsonContent }
                }
            } | ConvertTo-Json -Depth 6

            $targetLabel = if ($GistId) { $targetLabelUpdateTemplate -f @($GistId) } else { $targetLabelCreate }
            if (-not $PSCmdlet.ShouldProcess($targetLabel, $publishAction)) {
                Write-PSFMessage -Level Verbose -String 'PublishDevDirectoryList.PublishCanceled' -Tag "PublishDevDirectoryList", "Abort"
                return
            }

            if ($GistId) {
                Write-PSFMessage -Level Verbose -String 'PublishDevDirectoryList.UpdatingGist' -StringValues @($GistId) -Tag "PublishDevDirectoryList", "GistUpdate"
                $response = Invoke-RestMethod -Method Patch -Uri "$($gistEndpoint)/$GistId" -Headers $requestHeaders -Body $payload -ContentType "application/json"
            } else {
                Write-PSFMessage -Level Verbose -String 'PublishDevDirectoryList.CreatingGist' -Tag "PublishDevDirectoryList", "GistCreate"
                $response = Invoke-RestMethod -Method Post -Uri $gistEndpoint -Headers $requestHeaders -Body $payload -ContentType "application/json"
            }

            Write-PSFMessage -Level Verbose -String 'PublishDevDirectoryList.Complete' -StringValues @($response.id, $response.html_url) -Tag "PublishDevDirectoryList", "Complete"

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
            Write-PSFMessage -Level System -String 'PublishDevDirectoryList.CleanupTokens' -Tag "PublishDevDirectoryList", "Cleanup"
            if ($null -ne $requestHeaders -and $requestHeaders.ContainsKey("Authorization")) {
                $requestHeaders["Authorization"] = $null
            }

            $resolvedToken = $null
        }
    }
}
