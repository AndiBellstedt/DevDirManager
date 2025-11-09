function Resolve-RepositoryListFormat {
    <#
    .SYNOPSIS
        Resolves the repository list file format from a file path extension.

    .DESCRIPTION
        This internal helper function determines the file format (CSV, JSON, or XML) based on
        the file extension of a given path. It supports explicit format specification via
        parameter, extension-based inference, and fallback to a configured default format.

        The function is used across multiple public functions (Export-DevDirectoryList,
        Import-DevDirectoryList, Publish-DevDirectoryList) to ensure consistent format
        handling throughout the module.

    .PARAMETER Path
        The file path from which to extract the extension and infer the format.
        Can be a relative or absolute path.

    .PARAMETER Format
        Optional explicit format specification. If provided, this value is returned directly
        without any extension parsing. Valid values are "CSV", "JSON", or "XML".

    .PARAMETER DefaultFormat
        Optional default format to use when the file extension doesn't match known formats
        (csv, json, xml). If not provided and inference fails, the function will throw an error.

    .PARAMETER ErrorContext
        The context string to use in error messages when format inference fails.
        This should be the name of the calling function (e.g., "ExportDevDirectoryList").

    .OUTPUTS
        System.String
        Returns "CSV", "JSON", or "XML" indicating the resolved format.

    .EXAMPLE
        PS C:\> Resolve-RepositoryListFormat -Path "C:\repos\list.json"

        Returns "JSON" based on the .json extension.

    .EXAMPLE
        PS C:\> Resolve-RepositoryListFormat -Path "C:\repos\list.txt" -DefaultFormat "CSV"

        Returns "CSV" since the .txt extension is unknown and default format is specified.

    .EXAMPLE
        PS C:\> Resolve-RepositoryListFormat -Path "C:\repos\list.xml" -Format "JSON"

        Returns "JSON" since explicit format parameter overrides extension inference.

    .NOTES
        Version   : 1.0.1
        Author    : Copilot, Andi Bellstedt
        Date      : 2025-01-09
        Keywords  : format, inference, extension, repository, list
    #>
    [CmdletBinding()]
    [OutputType([string])]
    param (
        [Parameter(Mandatory = $true)]
        [string]
        $Path,

        [Parameter(Mandatory = $false)]
        [ValidateSet("CSV", "JSON", "XML")]
        [string]
        $Format,

        [Parameter(Mandatory = $false)]
        [ValidateSet("CSV", "JSON", "XML")]
        [string]
        $DefaultFormat,

        [Parameter(Mandatory = $false)]
        [string]
        $ErrorContext = "ResolveRepositoryListFormat"
    )

    begin {
        Write-PSFMessage -Level Debug -Message "Resolving format for path: '$($Path)', explicit Format: '$($Format)', DefaultFormat: '$($DefaultFormat)'" -Tag "ResolveRepositoryListFormat", "Start"

        # Early return if explicit format is provided
        if ($Format) {
            Write-PSFMessage -Level Verbose -Message "Using explicit format: $($Format)" -Tag "ResolveRepositoryListFormat", "Result"
            $Format
            return
        }

        # Extract file extension and convert to lowercase for comparison
        $extension = [System.IO.Path]::GetExtension($Path).ToLower()
        Write-PSFMessage -Level Debug -Message "Extracted extension: '$($extension)'" -Tag "ResolveRepositoryListFormat", "Inference"

        # Attempt to infer format from extension using regex matching
        $resolvedFormat = switch -Regex ($extension) {
            "^\.csv$" {
                Write-PSFMessage -Level Debug -Message "Inferred format from extension: CSV" -Tag "ResolveRepositoryListFormat", "Inference"
                "CSV"
            }
            "^\.json$" {
                Write-PSFMessage -Level Debug -Message "Inferred format from extension: JSON" -Tag "ResolveRepositoryListFormat", "Inference"
                "JSON"
            }
            "^\.xml$" {
                Write-PSFMessage -Level Debug -Message "Inferred format from extension: XML" -Tag "ResolveRepositoryListFormat", "Inference"
                "XML"
            }
            default {
                # Use the default format if provided when extension doesn't match
                if ($DefaultFormat) {
                    Write-PSFMessage -Level Verbose -String 'RepositoryList.UsingDefaultFormat' -StringValues @($DefaultFormat, $Path) -Tag "ResolveRepositoryListFormat", "Fallback"
                    $DefaultFormat
                } else {
                    # No default available, format inference failed
                    $messageValues = @($Path)
                    $messageTemplate = Get-PSFLocalizedString -Module 'DevDirManager' -Name "$($ErrorContext).InferFormatFailed"
                    $message = $messageTemplate -f $messageValues

                    # Throw a terminating error with proper PSFramework logging
                    Stop-PSFFunction -String "$($ErrorContext).InferFormatFailed" -StringValues $messageValues -EnableException $true
                    throw $message
                }
            }
        }

        Write-PSFMessage -Level Verbose -Message "Resolved format: '$($resolvedFormat)' for path: '$($Path)'" -Tag "ResolveRepositoryListFormat", "Result"
        # Return the resolved format
        $resolvedFormat
    }
}
