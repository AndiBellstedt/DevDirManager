function Add-RepositoryTypeName {
    <#
    .SYNOPSIS
        Adds the DevDirManager.Repository type name to PSObjects.

    .DESCRIPTION
        This internal helper function adds the custom type name 'DevDirManager.Repository'
        to PowerShell objects. This type name enables custom formatting and type-specific
        behavior defined in the module's format files (DevDirManager.Format.ps1xml).

        The function is primarily used by Import-DevDirectoryList when deserializing
        repository data from CSV, JSON, or XML files, ensuring that imported objects
        receive the same type information as objects created directly by Get-DevDirectory.

    .PARAMETER InputObject
        The PowerShell object(s) to which the type name should be added.
        Can be a single object or an array of objects.

    .OUTPUTS
        System.Management.Automation.PSObject
        Returns the input object(s) with the DevDirManager.Repository type name inserted
        at position 0 in the PSObject.TypeNames collection.

    .EXAMPLE
        PS C:\> $obj | Add-RepositoryTypeName

        Adds the DevDirManager.Repository type name to $obj and returns it.

    .EXAMPLE
        PS C:\> $objectList | Add-RepositoryTypeName

        Processes each object in the pipeline, adding the type name to all objects.

    .NOTES
        Version   : 1.0.0
        Author    : Copilot, Andi Bellstedt
        Date      : 2025-01-24
        Keywords  : type, typename, repository, psobject, formatting

    .LINK
        https://github.com/AndiBellstedt/DevDirManager
    #>
    [CmdletBinding()]
    [OutputType([PSObject])]
    param (
        [Parameter(
            Mandatory = $true,
            ValueFromPipeline = $true
        )]
        [PSObject[]]
        $InputObject
    )

    process {
        foreach ($obj in $InputObject) {
            # Insert the custom type name at position 0 to ensure it takes precedence
            # over any existing type names in the inheritance chain
            $obj.PSObject.TypeNames.Insert(0, 'DevDirManager.Repository')

            # Return the modified object to the pipeline
            $obj
        }
    }
}
