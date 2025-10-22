<#
    .SYNOPSIS
        This script publishes the module to the gallery.

    .DESCRIPTION
        This script publishes the module to the gallery.
        It expects as input an ApiKey authorized to publish the module.

        Insert any build steps you may need to take before publishing it here.

    .PARAMETER ModuleName
        The name to give to the module.

    .PARAMETER ApiKey
        The API key to use to publish the module to a Nuget repository

    .PARAMETER WorkingDirectory
        The root folder from which to build the module.

    .PARAMETER Repository
        The name of the repository to publish to.
        Defaults to PSGallery.

    .PARAMETER LocalRepo
        Instead of publishing to a gallery, drop a nuget package in the root folder.
        This package can then be picked up in a later step for publishing to Azure Artifacts.

    .PARAMETER SkipPublish
        Skips the publishing to the Nuget repository

    .PARAMETER AutoVersion
        Tells the publishing script to look for the versioning itself. Means,
        if the version in the module needs to be raised, the versioning mechanism
        will reaise the build number by +1
#>
param (
    $ModuleName = "DevDirManager",

    $ApiKey,

    $WorkingDirectory,

    $Repository = 'PSGallery',

    [switch]
    $LocalRepo,

    [switch]
    $SkipPublish,

    [bool]
    $AutoVersion = $true,

    [bool]
    $PreRelease = $false,

    [switch]
    $Build,

    [switch]
    $SkipModuleShrinking
)



#region -- prerequisites
# Handle Working Directory Defaults
if (-not $WorkingDirectory) {
    if ($env:RELEASE_PRIMARYARTIFACTSOURCEALIAS) {
        $WorkingDirectory = Join-Path -Path $env:SYSTEM_DEFAULTWORKINGDIRECTORY -ChildPath $env:RELEASE_PRIMARYARTIFACTSOURCEALIAS
    } else {
        $WorkingDirectory = $env:SYSTEM_DEFAULTWORKINGDIRECTORY
    }
}
if (-not $WorkingDirectory) { $WorkingDirectory = Split-Path $PSScriptRoot }

# Check module path
if (-not (Test-Path -Path "$($WorkingDirectory)\$($ModuleName)")) {
    Stop-PSFFunction -Message "Unable to find module '$($ModuleName)' at path '$($WorkingDirectory)\$($ModuleName)'. Maybe wrong module name or working directory specified. WorkingDirectory: '$WorkingDirectory'" -EnableException $true
}
#endregion prerequisites



#region -- Prepare module compilation
# Build Library
if ($Build) {
    dotnet build "$($WorkingDirectory)\library\$($ModuleName).sln"
    if ($LASTEXITCODE -ne 0) {
        throw "Failed to build $($ModuleName).dll!"
    }
}

# Prepare publish folder
Write-PSFMessage -Level Important -Message "Creating and populating publishing directory"
if (test-path "$($WorkingDirectory)\publish") { Remove-Item -Path "$($WorkingDirectory)\publish" -Recurse -Force -Confirm:$false }
$publishDir = New-Item -Path $WorkingDirectory -Name "publish" -ItemType Directory -Force
Copy-Item -Path "$($WorkingDirectory)\$($ModuleName)" -Destination $publishDir.FullName -Recurse -Force

$moduleDataFile = Import-PowerShellDataFile -Path "$($publishDir.FullName)\$($ModuleName)\$($ModuleName).psd1"
#endregion Prepare module compilation



#region Gather text data to compile
$text = @()
$processed = @()

# Gather Stuff to run before
foreach ($filePath in (& "$($PSScriptRoot)\..\$($ModuleName)\internal\scripts\preimport.ps1")) {
    if ([string]::IsNullOrWhiteSpace($filePath)) { continue }

    $item = Get-Item $filePath
    if ($item.PSIsContainer) { continue }
    if ($item.FullName -in $processed) { continue }
    $text += [System.IO.File]::ReadAllText($item.FullName)
    $processed += $item.FullName
}

# Gather commands
Get-ChildItem -Path "$($publishDir.FullName)\$($ModuleName)\internal\functions\" -Recurse -File -Filter "*.ps1" | ForEach-Object {
    $text += [System.IO.File]::ReadAllText($_.FullName)
    $processed += $_.FullName
}
Get-ChildItem -Path "$($publishDir.FullName)\$($ModuleName)\functions\" -Recurse -File -Filter "*.ps1" | ForEach-Object {
    $text += [System.IO.File]::ReadAllText($_.FullName)
    $processed += $_.FullName
}

# Gather stuff to run afterwards
foreach ($filePath in (& "$($PSScriptRoot)\..\$($ModuleName)\internal\scripts\postimport.ps1")) {
    if ([string]::IsNullOrWhiteSpace($filePath)) { continue }

    $item = Get-Item $filePath
    if ($item.PSIsContainer) { continue }
    if ($item.FullName -in $processed) { continue }
    $text += [System.IO.File]::ReadAllText($item.FullName)
    $processed += $item.FullName
}
#endregion Gather text data to compile



#region -- Update the psm1 file
$fileData = Get-Content -Path "$($publishDir.FullName)\$($ModuleName)\$($ModuleName).psm1" -Raw

$fileData = $fileData.Replace('"<was not compiled>"', '"<was compiled>"')
$fileData = $fileData.Replace('"<compile code into here>"', ($text -join "`n`n"))

[System.IO.File]::WriteAllText("$($publishDir.FullName)\$($ModuleName)\$($ModuleName).psm1", $fileData, [System.Text.Encoding]::UTF8)
#endregion Update the psm1 file



#region -- Remove processed files from publish directory
if (-not $SkipModuleShrinking) {
    foreach ($filePath in $processed) {
        Remove-Item -Path $filePath -Force
    }

    Remove-Item -Path "$($publishDir.FullName)\$($ModuleName)\tests" -Recurse -Force -Confirm:$false
    Remove-Item -Path "$($publishDir.FullName)\$($ModuleName)\functions" -Recurse -Force -Confirm:$false
    Remove-Item -Path "$($publishDir.FullName)\$($ModuleName)\internal\functions" -Recurse -Force -Confirm:$false
    Get-ChildItem -Path "$($publishDir.FullName)\$($ModuleName)\" -Filter "*.md" -Recurse -File | Where-Object Name -notlike "changelog.md" | Remove-Item -Force -Confirm:$false
}
#endregion Remove processed files from publish directory



#region -- Updating the Module Version
if ($AutoVersion -eq $true) {
    Write-PSFMessage -Level Important -Message "Checking for updating module version numbers."

    $remoteModule = Find-Module "$($ModuleName)" -Repository $Repository -ErrorAction SilentlyContinue
    [version]$remoteVersion = $remoteModule.Version
    if (-not $remoteVersion) { [version]$remoteVersion = [version]::new(0, 0, 0, 0) }

    [version]$localVersion = $moduleDataFile.ModuleVersion

    if ($remoteVersion -eq $localVersion) {
        [version]$newVersion = [version]::new($localVersion.Major, $localVersion.Minor, $remoteVersion.Build + 1, 0)
    } elseif ($remoteVersion -gt $localVersion) {
        [version]$newVersion = [version]::new($remoteVersion.Major, $remoteVersion.Minor, $remoteVersion.Build + 1, 0)
    } else {
        [version]$newVersion = $localVersion
    }

    Write-PSFMessage -Level Important -Message "Module version will be: $($ModuleName) $($newVersion)"
    Update-ModuleManifest -Path "$($publishDir.FullName)\$($ModuleName)\$($ModuleName).psd1" -ModuleVersion "$($newVersion)"
} else {
    Write-PSFMessage -Level Important -Message "Skipping module version number update, because AutoVersion is set to false."
    $newVersion = $moduleDataFile.ModuleVersion
}
#endregion Updating the Module Version



#region -- Publish the Module to Gallery
if ($SkipPublish) { return }


if ($LocalRepo -or $env:GITHUB_TOKEN) {

    # Dependencies must go first
    foreach ($dependency in $moduleDataFile.RequiredModules.ModuleName) {
        Write-PSFMessage -Level Important -Message "Creating Nuget Package for depending module '$($dependency)' in $($publishDir.FullName)"
        New-PSMDModuleNugetPackage -ModulePath (Get-Module -Name $dependency).ModuleBase -PackagePath "$($publishDir.FullName)"
    }

    # Publish the module to local path
    Write-PSFMessage -Level Important -Message "Creating Nuget Package for module '$($ModuleName)' in $($publishDir.FullName)"
    New-PSMDModuleNugetPackage -ModulePath "$($publishDir.FullName)\$($ModuleName)" -PackagePath "$($publishDir.FullName)"

} elseif (-not $LocalRepo) {

    # Get the Gallery repository
    $psrepository = Get-PSRepository -Name $Repository -ErrorAction SilentlyContinue

    if ($psrepository) {
        # Publish to PowerShell Gallery
        Write-PSFMessage -Level Important -Message "Publishing the $($ModuleName) module to $($Repository)"
        Publish-Module -Path "$($publishDir.FullName)\$($ModuleName)" -NuGetApiKey $ApiKey -Force -Repository $Repository
    } else {
        Write-PSFMessage -Level Important -Message "Repository '$($Repository)' not found. Skipping publish to this repository"
    }
}
#endregion Publish the Module to Gallery



#region -- Publish a github release
if ($env:GITHUB_TOKEN) {
    Write-PSFMessage -Level Important -Message "Publishing GitHub Release"

    $gitRepository = $env:GITHUB_REPOSITORY
    $token = $env:GITHUB_TOKEN
    $apiUrl = "https://api.github.com/repos/$($gitRepository)/releases"
    $headers = @{
        Authorization  = "token $($token)"
        'Content-Type' = 'application/json'
    }
    $jsonPayload = @{
        tag_name   = [string]$newVersion
        name       = [string]$newVersion
        prerelease = $PreRelease
    }

    $changeLogFileContent = Get-Content "$($publishDir.FullName)\$($ModuleName)\changelog.md" -ErrorAction SilentlyContinue | Where-Object { $_ -notlike "# ChangeLog" }
    if ($changeLogFileContent) {
        $changeLog = ("# $($ModuleName) $($newVersion)", ($changeLogFileContent -join "`n")) -join "`n"

        $jsonPayload.add("body", $changeLog)
        $jsonPayload.add("generate_release_notes", $false)
    } else {
        $jsonPayload.add("generate_release_notes", $true)
    }

    Write-PSFMessage -Level Important -Message "Pushing '$($ModuleName) $($newVersion)' release to '$($apiUrl)'"
    Write-PSFMessage -Level Verbose -Message "Payload details: $($jsonPayload | ConvertTo-Json -Depth 10 -Compress)" -Data $jsonPayload -Verbose

    $response = Invoke-RestMethod -Uri $apiUrl -Method Post -Body ($jsonPayload | ConvertTo-Json -Depth 10) -Headers $headers

    if ($response.id) {

        $file = Get-ChildItem "$($publishDir.FullName)\$($ModuleName).*.nupkg" -File
        $headerUpload = @{
            "Authorization" = "token $($token)"
            "Content-Type"  = "application/octet-stream"
            "name"          = $file.Name;
        }
        $fileBytes = [System.IO.File]::ReadAllBytes($file.FullName)
        $uriUpload = "https://uploads.github.com/repos/$($gitRepository)/releases/$($response.id)/assets?name=$($file.Name)"

        $response = Invoke-WebRequest -Headers $headerUpload -Method POST -Body $fileBytes -Uri $uriUpload

        if ($response) {
            Write-PSFMessage -Level Important -Message "GitHub Release created successfully"
        } else {
            Write-PSFMessage -Level Important -Message "GitHub Release not created."
        }
    } else {
        Write-PSFMessage -Level Important -Message "GitHub Release not created. Response: $($response | ConvertTo-Json -Depth 10 -Compress)"
    }
} else {
    Write-PSFMessage -Level Important -Message "GitHub Token not found. Skipping GitHub Release"
}
#endregion Publish a github release
