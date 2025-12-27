@{
    # Script module or binary module file associated with this manifest
    RootModule           = 'DevDirManager.psm1'

    # Version number of this module.
    ModuleVersion        = '1.4.2'

    # ID used to uniquely identify this module
    GUID                 = '6d7f0d28-926a-49ba-8a4f-d648b6ab6dff'

    # Author of this module
    Author               = 'Andi Bellstedt'

    # Company or vendor of this module
    #CompanyName       = ''

    # Copyright statement for this module
    Copyright            = 'Copyright (c) 2025 Andi Bellstedt'

    # Description of the functionality provided by this module
    Description          = 'A PowerShell module the easily manage local development folder with various git repositories across multiple computers.'

    # Which PowerShell Editions does this module work with? (Core, Desktop)
    CompatiblePSEditions = @('Desktop', 'Core')

    # Minimum version of the Windows PowerShell engine required by this module
    PowerShellVersion    = '5.1'

    # Modules that must be imported into the global environment prior to importing
    # this module
    RequiredModules      = @(
        @{ ModuleName = 'PSFramework'; ModuleVersion = '1.13.406' }
    )

    # Assemblies that must be loaded prior to importing this module
    # RequiredAssemblies = @('bin\DevDirManager.dll')

    # Type files (.ps1xml) to be loaded when importing this module
    TypesToProcess       = @('xml\DevDirManager.Types.ps1xml')

    # Format files (.ps1xml) to be loaded when importing this module
    FormatsToProcess     = @('xml\DevDirManager.Format.ps1xml')

    # Functions to export from this module
    FunctionsToExport    = @(
        'Export-DevDirectoryList'
        'Get-DevDirectory'
        'Import-DevDirectoryList'
        'Publish-DevDirectoryList'
        'Restore-DevDirectory'
        'Show-DevDirectoryDashboard'
        'Sync-DevDirectoryList'
    )

    # Cmdlets to export from this module
    CmdletsToExport      = @()

    # Variables to export from this module
    VariablesToExport    = @()

    # Aliases to export from this module
    AliasesToExport      = @()

    # List of all modules packaged with this module
    ModuleList           = @()

    # List of all files packaged with this module
    FileList             = @()

    # Private data to pass to the module specified in ModuleToProcess. This may also contain a PSData hashtable with additional module metadata used by PowerShell.
    PrivateData          = @{

        #Support for PowerShellGet galleries.
        PSData = @{

            # Tags applied to this module. These help with module discovery in online galleries.
            Tags         = @(
                'DevDirManager',
                'Git',
                'Repository',
                'Inventory',
                'Management',
                'LocalRepository',
                'LocalRepo',
                'GitRepo',
                'GitRepository',
                'Vibecoding',
                'EducatedPrompting'
            )

            # A URL to the license for this module.
            LicenseUri   = 'https://github.com/AndiBellstedt/DevDirManager/blob/main/LICENSE'

            # A URL to the main website for this project.
            ProjectUri   = 'https://github.com/AndiBellstedt/DevDirManager'

            # A URL to an icon representing this module.
            IconUri      = 'https://github.com/AndiBellstedt/DevDirManager/raw/main/assets/DevDirManager_128x128.png'

            # ReleaseNotes of this module
            ReleaseNotes = 'https://github.com/AndiBellstedt/DevDirManager/blob/main/DevDirManager/changelog.md'

        } # End of PSData hashtable

    } # End of PrivateData hashtable
}